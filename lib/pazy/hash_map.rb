# A Ruby version of Rich Hickey's persistent hash trie implementation
# from Clojure (http://clojure.org). Originally presented as a mutable
# structure in a paper by Phil Bagwell.
#
# To simplify the logic, the HashMap class only calls with() or
# without() on the root node if a change needs to be made. Thus
# there is no longer any special code in the node classes for
# optimizing idempotent operations.
#
# @author Olaf Delgado Friedrichs
# @author Rich Hickey
#
# This version: Copyright (c)2010 ANU Supercomputer Facility

# (Original copyright notice:)
# -------------------------------------------------------------------
# Copyright (c) Rich Hickey. All rights reserved.
# The use and distribution terms for this software are covered by the
# Eclipse Public License 1.0 (http://opensource.org/licenses/eclipse-1.0.php)
# which can be found in the file epl-v10.html at the root of this distribution.
# By using this software in any fashion, you are agreeing to be bound by
# the terms of this license.
# You must not remove this notice, or any other, from this software.
# -------------------------------------------------------------------

require 'pazy/helpers'
require 'pazy/enumerable'
require 'pazy/list'

module Pazy
  # The HashMap class provides the public API and serves as a wrapper
  # for the various node classes that hold the actual information.
  class HashMap
    include Pazy::Enumerable

    # The constructor creates an empty HashMap
    def self.new
      self.create
    end

    # A shorthand for HashMap.new.with()
    def self.with(key, value)
      self.new.with(key, value)
    end

    # Used internally by create to set the root node for an
    # instance. Once the root is set, the object is frozen (rendered
    # immutable).
    def initialize(root)
      @root = root
      freeze
    end

    # Tests if this map is empty.
    def empty?
      size == 0
    end

    # Returns the value associated to a key; synonym for get().
    def [](key)
      get(key)
    end

    # Returns the size of this map.
    def size
      @root.size
    end

    # If called with a block, iterates over the (key, value) pairs in
    # this map; otherwise, returns a corresponding enumerator object.
    def each(&block)
      if block_given?
        @root.each &block
      else
        self
      end
    end

    # The keys in this map.
    def keys
      self.map { |item| item[0] }
    end

    # The values in this map.
    def values
      self.map { |item| item[1] }
    end

    # The (key, value) pairs in this map.
    def entries
      each
    end

    # Retrieves the value associated with the given key, or nil if the
    # key is not present.
    def get(key)
      @root.get(0, key.hash, key)
    end

    # Returns a new map with the given key, value pair inserted, or
    # this map if it already contains that pair.
    def with(key, value)
      hash = key.hash
      if @root.get(0, hash, key) == value
        self
      else 
        self.class.create(@root.with(0, hash, key, value))
      end
    end

    # Returns a new map with the given key removed, or this map if it
    # does not contain that key.
    def without(key)
      hash = key.hash
      if @root.get(0, hash, key).nil?
        self
      else 
        self.class.create(@root.without(0, key.hash, key))
      end
    end

    # Returns a map obtained by adding all (key, values) pairs
    # contained in the given collection that were not already present
    # in this map.
    def +(enum)
      enum.inject(self) { |h, p| h.with *p }
    end

    # Returns a map obtained by removing all keys contained in the
    # given collection from this map.
    def -(enum)
      enum.inject(self) { |h, k| h.without k }
    end

    # Returns a map with the values transformed according to the block
    # given.
    def apply(&block)
      raise "No block given." unless block_given?
      self.class.new + map { |k, v| [k, block.call(v)] }
    end

    # This makes it possible to use a HashMap in place of a block
    # via the '&' prefix.
    def to_proc
      proc { |k| get(k) }
    end

    private
    @@empty = {} # one empty object per derived class

    # This method is used internally to create new instances. Empty
    # instances are cached, so that there is only one per class.
    def self.create(root = nil)
      if root.nil?
        if @@empty[self].nil?
          @@empty[self] = self.allocate
          @@empty[self].send :initialize, EmptyNode.new
        end
        obj = @@empty[self]
      else
        obj = self.allocate
        obj.send :initialize, root
      end
      obj
    end

    # This (singleton) class implements a root node for an empty map.
    class EmptyNode
      @@instance = nil

      def self.new
        @@instance ||= self.allocate
      end

      def size()
        0
      end

      def each
      end

      def get(shift, hash, key)
        nil
      end

      def with(shift, hash, key, value)
        LeafNode.new(hash, key, value)
      end
    end

    # A leaf node contains a single (key, value) pair and also caches
    # the hash value for the key.
    class LeafNode
      attr_reader :hash, :key, :value

      def initialize(hash, key, value)
        @key = key
        @hash = hash
        @value = value
        freeze
      end

      def size()
        1
      end

      def each
        yield [@key, @value]
      end

      def get(shift, hash, key)
        key == @key ? @value : nil
      end

      def with(shift, hash, key, value)
        if key == @key
          LeafNode.new(hash, key, value)
        elsif hash == @hash
          CollisionNode.new(hash, Pazy::List.make([@key, @value], [key, value]))
        else
          BitmapIndexedNode.make(shift, self).with(shift, hash, key, value)
        end
      end

      def without(shift, hash, key)
        key == @key ? nil : self
      end
    end

    # A collision node contains several (key, values) pairs in which
    # all keys have a common hash value, which is cached. The (key,
    # value) pairs are stored in a persistent list @bucket.
    class CollisionNode
      attr_reader :hash

      def initialize(hash, bucket)
        @hash = hash
        @bucket = bucket
        freeze
      end

      def size
        @bucket.size
      end

      def each(&block)
        @bucket.each &block
      end

      def get(shift, hash, key)
        (pair = get_entry(key)) && pair[1]
      end

      def with(shift, hash, key, value)
        if hash != @hash
          BitmapIndexedNode.make(shift, self).with(shift, hash, key, value)
        else
          new_bucket = @bucket.without(get_entry(key)).after([key, value])
          CollisionNode.new(hash, new_bucket)
        end
      end

      def without(shift, hash, key)
        new_bucket = @bucket.without(get_entry(key))
        if new_bucket.rest.empty?
          LeafNode.new(hash, *new_bucket.first)
        else
          CollisionNode.new(hash, new_bucket)
        end
      end

      private

      # Retrieves the (key, value) pair with the given key from the
      # bucket, if any.
      def get_entry(key)
        @bucket.find { |pair| pair[0] == key }
      end
    end

    class BitmapIndexedNode
      include Pazy::Helpers
      class << self; include Pazy::Helpers; end

      attr_reader :size

      def initialize(bitmap, array, size)
        @bitmap = bitmap
        @array = array
        @size = size
      end

      def self.make(shift, node)
        BitmapIndexedNode.new(1 << mask(node.hash, shift), [node], node.size)
      end

      def each(&block)
        @array.each { |v| v.each(&block) }
      end

      def get(shift, hash, key)
        bit, i = bitpos_and_index(@bitmap, hash, shift)
        @array[i].get(shift + 5, hash, key) if @bitmap & bit != 0
      end

      def with(shift, hash, key, value)
        bit, i = bitpos_and_index(@bitmap, hash, shift)

        if @bitmap & bit == 0
          new_node = LeafNode.new(hash, key, value)
          n = bitcount(@bitmap)
          if n < 8
            new_array = array_with_insertion(i, new_node)
            BitmapIndexedNode.new(@bitmap | bit, new_array, @size + 1)
          else
            table = (0..31).map do |m|
              b = 1 << m
              @array[index_for_bit(@bitmap, b)] if @bitmap & b != 0
            end
            ArrayNode.new(table, mask(hash, shift), new_node, @size + 1)
          end
        else
          v = @array[i]
          node = v.with(shift + 5, hash, key, value)
          new_size = @size + node.size - v.size
          BitmapIndexedNode.new(@bitmap, array_with(i, node), new_size)
        end
      end

      def without(shift, hash, key)
        bit, i = bitpos_and_index(@bitmap, hash, shift)

        v = @array[i]
        node = v.without(shift + 5, hash, key)
        if node
          new_size = @size + node.size - v.size
          BitmapIndexedNode.new(@bitmap, array_with(i, node), new_size)
        else
          new_bitmap = @bitmap ^ bit
          case bitcount(new_bitmap)
          when 0
            nil
          when 1
            array_without(i)[0]
          else
            BitmapIndexedNode.new(new_bitmap, array_without(i), @size - 1)
          end
        end
      end

      private

      def array_with(i, node)
        @array[0, i] + [node] + @array[i+1 ... @array.length]
      end

      def array_with_insertion(i, node)
        @array[0, i] + [node] + @array[i ... @array.length]
      end

      def array_without(i)
        @array[0, i] + @array[i+1 ... @array.length]
      end
    end

    class ArrayNode
      include Pazy::Helpers

      attr_reader :size

      def initialize(table, i, node, size)
        @table = table.clone; @table[i] = node
        @size  = size
        freeze
      end

      def each(&block)
        @table.each { |node| node.each(&block) unless node.nil? }
      end

      def get(shift, hash, key)
        i = mask(hash, shift)
        @table[i] && @table[i].get(shift + 5, hash, key)
      end

      def with(shift, hash, key, value)
        i = mask(hash, shift)

        if @table[i].nil?
          node = LeafNode.new(hash, key, value)
          ArrayNode.new(@table, i, node, size + 1)
        else
          node = @table[i].with(shift + 5, hash, key, value)
          new_size = size + node.size - @table[i].size
          ArrayNode.new(@table, i, node, new_size)
        end
      end

      def without(shift, hash, key)
        i = mask(hash, shift)

        node = @table[i].without(shift + 5, hash, key)
        if node
          ArrayNode.new(@table, i, node, size - 1)
        else
          remaining = (1...@table.length).select { |j| j != i and @table[j] }
          if remaining.length <= 4
            bitmap = remaining.inject(0)  { |b,j| b | (1 << j) }
            array  = remaining.map { |j| @table[j] }
            BitmapIndexedNode.new(bitmap, array, size - 1)
          else
            ArrayNode.new(@table, i, nil, size - 1)
          end
        end
      end
    end
  end
end
