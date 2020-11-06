using HTTP, Gumbo, Cascadia, Dates, JSON

PROFILE_URL = "https://colonist.io/api/profile" #"https://colonist.io/profile"
COOKIE = "_ga=GA1.2.456225344.1599180098; Indicative_a38719f2-d919-446b-b2e3-0da55a22a29a=\"%7B%22defaultUniqueID%22%3A%22dda3b884-9719-44c7-8a3f-0e58b3cee020%22%7D\"; __qca=P0-58763845-1599180099331; __stripe_mid=db19d11e-0bcf-4b6f-9159-ecd3accd3ccb282899; _gid=GA1.2.1609056974.1604216954; __cfduid=dde81de7409c5333a4aa84bd790ac87ae1604481036; _gat_gtag_UA_111427971_1=1; jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiIyNTIxNTE4IiwiaWF0IjoxNjA0NjMzODY0LCJleHAiOjE2MDcyMjU4NjQsImF1ZCI6Imh0dHBzOi8vY29sb25pc3QuaW8vIiwiaXNzIjoiaHR0cHM6Ly9jb2xvbmlzdC5pby8ifQ.NfOGuPDgo52zWBQ6JJ9koj2oLkn1n3EfJE747_14Kqk"


user_url(user) = "$PROFILE_URL/$user"
info_from_url(url, headers) = HTTP.request("GET", url, headers=headers).body |> String |> JSON.parse
user_info(user) = info_from_url(user_url(user), ["cookie" => COOKIE])


url = "https://colonist.io/api/profile/ZacTodd"
print(user_info("ZacTodd"))