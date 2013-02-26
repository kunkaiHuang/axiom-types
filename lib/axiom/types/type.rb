# encoding: utf-8

module Axiom
  module Types

    # Abstract base class for every type
    class Type
      extend Options, DescendantsTracker

      accept_options :constraint
      constraint proc { true }

      def self.new(constraint = Undefined, &block)
        ::Class.new(self) do
          constraint(constraint)
          instance_exec(&block) if block
          finalize
        end
      end

      def self.finalize
        IceNine.deep_freeze(@constraint)
        freeze
      end

      def self.finalized?
        frozen?
      end

      def self.include?(object)
        included = constraint.call(object)
        if included != true && included != false
          raise TypeError,
            "constraint must return true or false, but was #{included.inspect}"
        end
        included
      end

      def self.constraint(constraint = Undefined, &block)
        constraint = block if constraint.equal?(Undefined)
        return @constraint if constraint.nil?
        add_constraint(constraint)
        self
      end

      singleton_class.class_eval { protected :constraint }

      # TODO: move this into a module. separate the constraint setup from
      # declaration of the members, like the comparable modules.
      def self.includes(*members)
        set = IceNine.deep_freeze(members.to_set)
        constraint(&set.method(:include?))
      end

      def self.add_constraint(constraint)
        current = @constraint
        @constraint = if current
          lambda { |object| current.call(object) && constraint.call(object) }
        else
          constraint
        end
      end

      private_class_method :includes, :add_constraint

    end # class Type
  end # module Types
end # module Axiom
