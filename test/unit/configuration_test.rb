require "test_helper"

class ConfigurationTest < ActiveSupport::TestCase
  test "default configuration to process all queues and dispatch" do
    configuration = stub_const(SolidQueue::Configuration, :DEFAULT_CONFIG_FILE_PATH, "non/existent/path") do
      SolidQueue::Configuration.new
    end

    assert_equal 2, configuration.processes.count

    assert_equal 1, configuration.workers.count
    assert_equal 1, configuration.dispatchers.count

    assert_equal [ "*" ], configuration.workers.first.queues
    assert_equal SolidQueue::Configuration::DISPATCHER_DEFAULTS[:batch_size], configuration.dispatchers.first.batch_size
  end

  test "read configuration from default file" do
    configuration = SolidQueue::Configuration.new
    assert 3, configuration.processes.count
    assert_equal 2, configuration.workers.count
    assert_equal 1, configuration.dispatchers.count
  end

  test "provide configuration as a hash and fill defaults" do
    background_worker = { queues: "background", polling_interval: 10 }
    dispatcher = { batch_size: 100 }
    config_as_hash = { workers: [ background_worker, background_worker ], dispatchers: [ dispatcher ] }
    configuration = SolidQueue::Configuration.new(load_from: config_as_hash)

    assert_equal 1, configuration.dispatchers.count
    dispatcher = configuration.dispatchers.first
    assert_equal SolidQueue::Configuration::DISPATCHER_DEFAULTS[:polling_interval], dispatcher.polling_interval
    assert_equal SolidQueue::Configuration::DISPATCHER_DEFAULTS[:concurrency_maintenance_interval], dispatcher.concurrency_maintenance.interval

    assert_equal 2, configuration.workers.count
    assert_equal [ "background" ], configuration.workers.flat_map(&:queues).uniq
    assert_equal [ 10 ], configuration.workers.map(&:polling_interval).uniq

    config_as_hash = { workers: [ background_worker, background_worker ] }
    configuration = SolidQueue::Configuration.new(load_from: config_as_hash)
    assert_empty configuration.dispatchers
    assert_equal 2, configuration.workers.count
  end

  test "max number of threads" do
    configuration = SolidQueue::Configuration.new
    assert 7, configuration.max_number_of_threads
  end

  test "mulitple workers with the same configuration" do
    background_worker = { queues: "background", polling_interval: 10, processes: 3 }
    config_as_hash = { workers: [ background_worker ] }
    configuration = SolidQueue::Configuration.new(load_from: config_as_hash)

    assert_equal 3, configuration.workers.count
    assert_equal [ "background" ], configuration.workers.flat_map(&:queues).uniq
    assert_equal [ 10 ], configuration.workers.map(&:polling_interval).uniq
  end

  test "ignore processes option on async mode" do
    background_worker = { queues: "background", polling_interval: 10, processes: 3 }
    config_as_hash = { workers: [ background_worker ] }
    configuration = SolidQueue::Configuration.new(mode: :async, load_from: config_as_hash)

    assert_equal 1, configuration.workers.count
    assert_equal [ "background" ], configuration.workers.first.queues
    assert_equal 10, configuration.workers.first.polling_interval
  end
end
