# frozen_string_literal: true

class DalliClientMock
  def version
    @version ||= Version.new
  end

  def get(_key); end
  def set(_key, _value, _opts); end
  def delete(_key); end

  class Version
    def fetch(_, _) = 1.23
  end
end
