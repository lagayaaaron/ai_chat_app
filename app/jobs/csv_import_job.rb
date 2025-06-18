class CsvImportJob < ApplicationJob
  queue_as :default

  def perform(file_path)
    CsvImportService.new(file_path).import
  end
end
