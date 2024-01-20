# frozen_string_literal: true

require 'spec_helper'
require 'hawk/linker'

class Author < Hawk::Model::Base
  url 'https://example.org/'
  client_name 'Foobar'

  schema do
    integer :id
    string :name
  end
end

class Post
  attr_accessor :author_id

  include Hawk::Linker

  resource_accessor :author
end

RSpec.describe Hawk::Linker do
  let(:author_attributes) do
    {
      id: 1,
      name: 'Stendhal'
    }
  end

  describe 'remote resource loading' do
    specify do
      stub_request(:GET, 'https://example.org/authors/1')
        .with(headers: { 'User-Agent' => 'Foobar' })
        .to_return(status: 200, body: author_attributes.to_json, headers: {})

      post = Post.new.tap { |p| p.author_id = 1 }
      author = post.author

      expect(author).to be_a(Author)
      expect(author.name).to eq('Stendhal')
    end
  end
end
