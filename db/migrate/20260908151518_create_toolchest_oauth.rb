class CreateToolchestOauth < ActiveRecord::Migration[8.0]
  def change
    create_table :toolchest_oauth_applications do |t|
      t.string  :name,         null: false
      t.string  :uid,          null: false, index: { unique: true }
      t.string  :secret
      t.text    :redirect_uri, null: false
      t.string  :scopes,       null: false, default: ""
      t.boolean :confidential, null: false, default: true
      t.timestamps
    end

    create_table :toolchest_oauth_access_grants do |t|
      t.string     :resource_owner_id, null: false
      t.references :application, null: false, foreign_key: { to_table: :toolchest_oauth_applications }
      t.string     :token_digest, null: false, index: { unique: true }
      t.text       :redirect_uri, null: false
      t.string     :scopes,     null: false, default: ""
      t.string     :code_challenge
      t.string     :code_challenge_method
      t.string     :mount_key, null: false, default: "default"
      t.datetime   :expires_at, null: false
      t.datetime   :revoked_at
      t.timestamps
    end

    create_table :toolchest_oauth_access_tokens do |t|
      t.string     :resource_owner_id
      t.references :application, null: false, foreign_key: { to_table: :toolchest_oauth_applications }
      t.string     :token,         null: false, index: { unique: true }
      t.string     :refresh_token, index: { unique: true }
      t.string     :scopes
      t.string     :mount_key, null: false, default: "default"
      t.datetime   :expires_at
      t.datetime   :revoked_at
      t.timestamps
    end
  end
end
