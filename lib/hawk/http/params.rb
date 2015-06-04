module Hawk
  class HTTP

    require 'ethon/easy/queryable'

    class Params
      include Ethon::Easy::Queryable

      def initialize(params)
        @params = params
      end

      # The API endpoint server requires that array parameters do not have
      # indexes. This hack uses all Typhoeus' machinery but eventually deletes
      # array indexes enclosed in square brackets.
      #
      def to_s
        super.gsub(/\[\d+\]/, '[]')
      end

    end
  end
end
