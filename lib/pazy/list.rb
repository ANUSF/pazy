require 'pazy/enumerable'

module Pazy
  class List
    include Pazy::Enumerable

    def self.new
      Empty.instance
    end

    def after(item)
      Cons.new item, self
    end

    def self.make(*args)
      args.reverse.inject(List.new) { |a, x| Cons.new x, a }
    end

    def self.from_enum(enum)
      List.make *enum.to_a
    end

    private

    class Empty < List
      @@instance = nil

      def self.instance
        @@instance ||= self.allocate
      end

      def empty?
        true
      end

      def size
        0
      end

      def each
        self unless block_given?
      end

      def without(item)
        self
      end
    end

    class Cons < List
      attr_reader :first, :rest, :size

      def self.new(*args)
        obj = self.allocate
        obj.send :initialize, *args
        obj
      end

      def initialize(first, rest)
        rest = List.new if rest.nil?
        raise "second argument must be a List or nil" unless rest.is_a? List
        @first = first
        @rest = rest
        @size = 1 + rest.size
        freeze
      end

      def empty?
        false
      end

      def each(&block)
        if block_given?
          block.call @first
          @rest.each &block
        else
          self
        end
      end

      def without(item, force_clone = false)
        if force_clone == true or find { |x| x == item }
          if @first == item
            @rest
          else
            Cons.new(@first, @rest.without(item, true))
          end
        else
          self
        end
      end
    end
  end
end
