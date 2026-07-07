# frozen_string_literal: true

module Census
  # Runs the certificate stages over every unresolved shape.json under root,
  # verifying and stamping verdicts as it goes. Yields one line per solved shape.
  class Pipeline
    def initialize(root:, max_index: TorusSearch::DEFAULT_MAX_INDEX, max_volume: BoxSearch::DEFAULT_MAX_VOLUME)
      @root = Pathname(root)
      @max_index = max_index
      @max_volume = max_volume
    end

    def run(max_size:, shard_count: 1, shard_index: 1, &report)
      (1..max_size).each do |size|
        record_paths(size, shard_count:, shard_index:).each { process(it, &report) }
      end
    end

    private

    attr_reader :max_index, :max_volume, :root

    def record_paths(size, shard_count:, shard_index:)
      Dir.glob(root.join(size.to_s, "*", "shape.json").to_s)
         .sort_by { Integer(File.basename(File.dirname(it))) }
         .select { Integer(File.basename(File.dirname(it))) % shard_count == shard_index % shard_count }
    end

    def process(path, &report)
      record = JSON.parse(File.read(path), symbolize_names: true)
      return if record[:verdict]

      shape = Polycube.new(cells: record[:cells])
      certificate = BoxSearch.new(shape:, max_volume:).certificate ||
                    TorusSearch.new(shape:, max_index:).certificate
      return unless certificate

      stamp(path, record, shape, certificate)
      report&.call("#{record[:id]}  tiler  #{describe(certificate)}")
    end

    def describe(certificate)
      case certificate[:type]
      when "box"   then "box #{certificate[:box].join('x')}"
      when "torus" then "torus index #{Lattice.new(basis: certificate[:lattice]).index}"
      end
    end

    def stamp(path, record, shape, certificate)
      raise "certificate failed verification for #{record[:id]}" unless Verifier.new(certificate:, shape:).valid?

      File.write(path, JSONDocument.generate(tiler_fields(record, certificate)))
    end

    def tiler_fields(record, certificate)
      record.merge(
        verdict: "tiler",
        tiles_rotations_only: true,
        tiles_with_reflections: true,
        certificate:,
        budgets: { box_max_volume: max_volume, torus_max_index: max_index },
        credits: record[:credits].merge(solved_by: "polycube-census v#{VERSION}")
      )
    end
  end
end
