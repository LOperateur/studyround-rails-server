# frozen_string_literal: true
# Class extension from ActiveModelSerializers that merges the `meta` hash
# as part of the root Json
module ActiveModelSerializers
  module Adapter
    class Json < Base
      def serializable_hash(options = nil)
        options = serialization_options(options)
        serialized_hash = { root => Attributes.new(serializer, instance_options).serializable_hash(options) }
        serialized_hash.merge! meta unless meta.blank?

        self.class.transform_key_casing!(serialized_hash, instance_options)
      end
    end
  end
end
