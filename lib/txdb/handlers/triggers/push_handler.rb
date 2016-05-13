module Txdb
  module Handlers
    module Triggers

      class PushHandler < Handler
        def handle
          tables.each do |table|
            Uploader.new(table.database).upload_table(table)
          end

          respond_with(200, {})
        end
      end

    end
  end
end
