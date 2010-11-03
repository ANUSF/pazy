module Pazy
  module Attributes
    def self.included(base)
      base.class_eval do
        extend Pazy::Attributes::ClassMethods
        include Pazy::Attributes::InstanceMethods
      end
    end

    module ClassMethods
      def lazy_attr(name, &block)
        define_method(name) do
          (@__lazy_cache__ ||= {})[name] ||= instance_eval(&block)
        end
      end
    end

    module InstanceMethods
      def freeze
        @__lazy_cache__ = {}
        super
      end
    end
  end
end
