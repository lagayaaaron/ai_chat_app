require "csv"

class CsvImportService
  def initialize(file_path)
    @file_path = file_path
  end

  def import
    CSV.foreach(@file_path, headers: true) do |row|
      Document.create!(
        issuance_no: row["issuance_no"],
        doc_date: row["doc_date"] ? DateTime.parse(row["doc_date"]) : nil,
        content: row["content"]
      )
    end
  end
end
