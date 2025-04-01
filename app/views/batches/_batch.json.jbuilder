json.extract! batch, :id, :created_at, :updated_at
json.url batch_url(batch, format: :json)
json.csv_filename batch.csv.filename
