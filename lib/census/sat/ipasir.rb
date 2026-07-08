# frozen_string_literal: true

require "ffi"

module Census
  module SAT
    # IPASIR — the standard incremental SAT C API — via the ffi gem: solver
    # calls with no process spawn, no DIMACS file, no output parsing. Works
    # with any conforming library (CaDiCaL from Homebrew now; kissat once its
    # library is built). Not required by census.rb: spike code, opt-in.
    module IPASIR
      extend FFI::Library

      LIBRARY = ENV.fetch(
        "CENSUS_IPASIR_LIB",
        File.expand_path("../../../vendor/libipasir-cadical.dylib", __dir__)
      )
      ffi_lib LIBRARY

      attach_function :ipasir_init, [], :pointer
      attach_function :ipasir_release, [:pointer], :void
      attach_function :ipasir_add, %i[pointer int32], :void
      attach_function :ipasir_solve, [:pointer], :int
      attach_function :ipasir_val, %i[pointer int32], :int32

      SATISFIABLE = 10
      UNSATISFIABLE = 20

      def self.solve(instance)
        solver = ipasir_init
        instance.clauses.each do |clause|
          clause.each { ipasir_add(solver, it) }
          ipasir_add(solver, 0)
        end
        interpret(solver, instance)
      ensure
        ipasir_release(solver) if solver && !solver.null?
      end

      def self.interpret(solver, instance)
        case ipasir_solve(solver)
        when SATISFIABLE
          (1..instance.variable_count).select { ipasir_val(solver, it).positive? }.to_set
        when UNSATISFIABLE then nil
        else raise "ipasir solver returned neither SAT nor UNSAT"
        end
      end
    end
  end
end
