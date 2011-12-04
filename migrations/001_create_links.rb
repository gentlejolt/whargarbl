Sequel.migration do
  change do
    create_table(:links) do
      primary_key :id
      String :nick, :null=>false
      String :href, :text=>true
    end
  end
end