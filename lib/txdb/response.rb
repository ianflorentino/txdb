module Txdb
  class Response
    attr_reader :status, :body, :error

    def initialize(status, body, error = nil)
      @status = status
      @body = body
      @error = error
    end
  end
end
