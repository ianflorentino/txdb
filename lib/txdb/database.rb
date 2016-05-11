require 'sequel'

module Txdb
  class Database
    DEFAULT_HOST = '127.0.0.1'
    DEFAULT_PORT = '3306'
    DEFAULT_POOL = 10

    attr_reader :adapter, :backend, :username, :password, :host, :port, :database
    attr_reader :pool, :transifex_project, :tables

    def initialize(options = {})
      @adapter = options.fetch('adapter')
      @backend = Txdb::Backends.get(options.fetch('backend'))
      @username = options.fetch('username')
      @password = options.fetch('password')
      @host = options.fetch('host', DEFAULT_HOST)
      @port = options.fetch('port', DEFAULT_PORT)
      @database = options.fetch('database')
      @pool = options.fetch('pool', DEFAULT_POOL)
      @transifex_project = TransifexProject.new(options.fetch('transifex'))
      @tables = options.fetch('tables').map do |table_config|
        Table.new(self, table_config)
      end
    end

    def db
      @db ||= Sequel.connect(connection_string, max_connections: pool)
    end

    def connection_string
      "#{adapter}://#{username}:#{password}@#{host}:#{port}/#{database}"
    end

    def from(*args, &block)
      db.from(*args, &block)
    end

    def [](*args, &block)
      db.send(:[], *args, &block)
    end

    def transifex_api
      transifex_project.api
    end
  end
end
