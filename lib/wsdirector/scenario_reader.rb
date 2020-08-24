# frozen_string_literal: true

require "erb"

module WSDirector
  # Read and parse YAML scenario
  class ScenarioReader
    class << self
      include WSDirector::Utils

      def parse(file_path)
        contents = ::YAML.load(ERB.new(File.read(file_path)).result)

        if contents.first.key?("client")
          parse_multiple_scenarios(contents)
        else
          { "total" => 1, "clients" => [parse_simple_scenario(contents)] }
        end
      end

      private

      def handle_steps(steps)
        steps.flat_map do |step|
          if step.is_a?(Hash)
            type, data = step.to_a.first
            multiplier = parse_multiplier(data.delete("multiplier") || "1")
            Array.new(multiplier) { { "type" => type }.merge(data) }
          else
            { "type" => step }
          end
        end
      end

      def parse_simple_scenario(
          steps,
          multiplier: 1, name: "default", ignore: nil, protocol: "base"
      )
        {
          "multiplier" => multiplier,
          "steps" => handle_steps(steps),
          "name" => name,
          "ignore" => ignore,
          "protocol" => protocol
        }
      end

      def parse_multiple_scenarios(definitions)
        total_count = 0
        clients = definitions.map.with_index do |client, i|
          _, client = client.to_a.first
          multiplier = parse_multiplier(client.delete("multiplier") || "1")
          name = client.delete("name") || (i + 1).to_s
          total_count += multiplier
          ignore = parse_ingore(client.fetch("ignore", nil))
          parse_simple_scenario(
            client.fetch("actions", []),
            multiplier: multiplier,
            name: name,
            ignore: ignore,
            protocol: client.fetch("protocol", "base")
          )
        end
        { "total" => total_count, "clients" => clients }
      end

      def parse_ingore(str)
        return unless str

        Array(str)
      end
    end
  end
end
