module Solargraph
  class TypeChecker
    module Checks
      module_function

      # Compare an expected type with an inferred type. Common usage is to
      # check if the type declared in a method's @return tag matches the type
      # inferred from static analysis of the code.
      #
      # @param api_map [ApiMap]
      # @param expected [ComplexType]
      # @param inferred [ComplexType]
      # @return [Boolean]
      def types_match? api_map, expected, inferred
        return true if expected.to_s == inferred.to_s
        matches = []
        expected.each do |exp|
          found = false
          inferred.each do |inf|
            if api_map.super_and_sub?(fuzz(exp), fuzz(inf))
              found = true
              matches.push inf
              break
            end
          end
          return false unless found
        end
        inferred.each do |inf|
          next if matches.include?(inf)
          found = false
          expected.each do |exp|
            if api_map.super_and_sub?(fuzz(exp), fuzz(inf))
              found = true
              break
            end
          end
          return false unless found
        end
        true
      end

      # @param api_map [ApiMap]
      # @param expected [ComplexType]
      # @param inferred [ComplexType]
      # @return [Boolean]
      def any_types_match? api_map, expected, inferred
        return duck_types_match?(api_map, expected, inferred) if expected.duck_type?
        expected.each do |exp|
          next if exp.duck_type?
          inferred.each do |inf|
            return true if exp == inf || api_map.super_and_sub?(fuzz(exp), fuzz(inf))
          end
        end
        false
      end

      # @param api_map [ApiMap]
      # @param expected [ComplexType]
      # @param inferred [ComplexType]
      # @return [Boolean]
      def duck_types_match? api_map, expected, inferred
        raise ArgumentError, "Expected type must be duck type" unless expected.duck_type?
        expected.each do |exp|
          next unless exp.duck_type?
          quack = exp.to_s[1..-1]
          return false if api_map.get_method_stack(inferred.namespace, quack, scope: inferred.scope).empty?
        end
        true
      end

      # @param type [ComplexType]
      # @return [String]
      def fuzz type
        if type.parameters?
          type.name
        else
          type.tag
        end
      end
    end
  end
end
