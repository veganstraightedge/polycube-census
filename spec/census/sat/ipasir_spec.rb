# frozen_string_literal: true

library = File.expand_path("../../../vendor/libipasir-cadical.dylib", __dir__)

RSpec.describe "Census::SAT::IPASIR", skip: (File.exist?(library) ? false : "run script/build-ipasir first") do
  before(:all) { require "census/sat/ipasir" }

  def pigeonhole(pigeons)
    holes = pigeons - 1
    instance = Census::SAT::Instance.new
    nests = Array.new(pigeons) { Array.new(holes) { instance.new_variable } }
    nests.each { instance.add_clause(it) }
    (0...holes).each do |hole|
      (0...pigeons).to_a.combination(2) { |a, b| instance.add_clause([-nests[a][hole], -nests[b][hole]]) }
    end
    instance
  end

  it "agrees with the subprocess solver on a satisfiable instance" do
    instance = Census::SAT::Instance.new
    first = instance.new_variable
    second = instance.new_variable
    instance.add_clause([first, second])
    instance.add_clause([-first])
    expect(Census::SAT::IPASIR.solve(instance)).to eq(Census::SAT::Kissat.solve(instance))
  end

  it "refutes the pigeonhole principle like everyone else" do
    expect(Census::SAT::IPASIR.solve(pigeonhole(5))).to be_nil
  end

  it "routes Kissat.solve through the ffi engine when CENSUS_FFI=1" do
    instance = Census::SAT::Instance.new
    only = instance.new_variable
    instance.add_clause([only])
    ENV["CENSUS_FFI"] = "1"
    expect(Census::SAT::Kissat.solve(instance)).to eq(Set[only])
  ensure
    ENV.delete("CENSUS_FFI")
  end

  it "solves repeatedly without leaking state between calls" do
    instance = Census::SAT::Instance.new
    only = instance.new_variable
    instance.add_clause([only])
    results = Array.new(50) { Census::SAT::IPASIR.solve(instance) }
    expect(results.uniq).to eq([Set[only]])
  end
end
