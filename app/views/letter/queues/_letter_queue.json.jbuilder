json.extract! letter_queue, :id, :name, :slug, :user_id, :created_at, :updated_at
json.url letter_queue_url(letter_queue, format: :json)
