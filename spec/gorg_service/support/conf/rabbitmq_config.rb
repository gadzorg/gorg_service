require 'yaml'

class RabbitmqConfig
  def self.value_at key
    @conf||=YAML::load(File.open(File.expand_path('../rabbit_mq.yml', __FILE__)))
    @conf[key]
  end
end