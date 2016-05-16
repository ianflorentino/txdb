require 'spec_helper'
require 'spec_helpers/test_backend'
require 'spec_helpers/test_db'
require 'uri'
require 'yaml'

include Txdb::Handlers::Triggers

describe PullHandler do
  include Rack::Test::Methods

  let(:database) { TestDb.database }
  let(:table) { database.tables.first }
  let(:project) { database.transifex_project }

  def app
    Txdb::Triggers
  end

  before(:each) do
    allow(Txdb::Config).to receive(:databases).and_return([database])
  end

  let(:params) do
    { 'database' => database.database, 'table' => table.name }
  end

  it 'downloads the table for each locale' do
    locales = [{ 'language_code' => 'es' }, { 'language_code' => 'ja' }]
    content = { 'phrase' => 'trans' }
    expect(database.transifex_api).to receive(:get_languages).and_return(locales)
    allow(database.transifex_api).to receive(:download).and_return(YAML.dump(content))

    expect { patch('/pull', params) }.to(
      change { Txdb::TestBackend.writes.size }.from(0).to(2)
    )

    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq('{}')

    expect(Txdb::TestBackend.writes).to include(
      locale: 'es', table: table.name, content: content
    )

    expect(Txdb::TestBackend.writes).to include(
      locale: 'ja', table: table.name, content: content
    )
  end

  it 'reports errors' do
    expect(database.transifex_api).to receive(:get_languages).and_raise('jelly beans')
    patch '/pull', params
    expect(last_response.status).to eq(500)
    expect(JSON.parse(last_response.body)).to eq(
      [{ 'error' => 'Internal server error: jelly beans' }]
    )
  end
end