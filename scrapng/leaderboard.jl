using HTTP, Gumbo, Cascadia, Dates, JSON, DataStructures

PROFILE_URL = "https://colonist.io/api/profile" #"https://colonist.io/profile"
COOKIE = "_ga=GA1.2.456225344.1599180098; Indicative_a38719f2-d919-446b-b2e3-0da55a22a29a=\"%7B%22defaultUniqueID%22%3A%22dda3b884-9719-44c7-8a3f-0e58b3cee020%22%7D\"; __qca=P0-58763845-1599180099331; __stripe_mid=db19d11e-0bcf-4b6f-9159-ecd3accd3ccb282899; _gid=GA1.2.1609056974.1604216954; __cfduid=dde81de7409c5333a4aa84bd790ac87ae1604481036; _gat_gtag_UA_111427971_1=1; jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiIyNTIxNTE4IiwiaWF0IjoxNjA0NjMzODY0LCJleHAiOjE2MDcyMjU4NjQsImF1ZCI6Imh0dHBzOi8vY29sb25pc3QuaW8vIiwiaXNzIjoiaHR0cHM6Ly9jb2xvbmlzdC5pby8ifQ.NfOGuPDgo52zWBQ6JJ9koj2oLkn1n3EfJE747_14Kqk"


user_url(user) = "$PROFILE_URL/$user"
info_from_url(url, headers) = HTTP.request("GET", url, headers=headers).body |> String |> JSON.parse
user_info(user) = info_from_url(user_url(user), ["cookie" => COOKIE])


binimal_prob(x::BigInt, p::BigFloat) = binomial(BigInt(100), x) * (p ^ x) * ((1 - p) ^ (100 - x))
binimal_prob_less_than_equal(x::BigInt, p::BigFloat) = sum(binimal_prob(i, p) for i in 1:x)


function get_players(start_user="ZacTodd")
    players_winrate = Dict()
    seen = Set([start_user])

    q = Queue{String}()
    enqueue!(q, start_user)
    while length(q) != 0
        p = dequeue!(q)
        player_info = user_info(p)

        num_players_list = []
        push!(players_winrate, p => player_info["winsInLast100Games"])
        for g in player_info["gameDatas"]
            append!(num_players_list, length(g["players"]))
            for op in g["players"]
                username = op["username"]
                if !occursin("#", username) && !(username in seen)
                    push!(seen, username)
                    enqueue!(q, username)
                end
            end
        end

        winrate = player_info["winsInLast100Games"]

        try
            avg_players = sum(num_players_list) / length(num_players_list)

            score =  1 - binimal_prob_less_than_equal(BigInt(winrate), BigFloat(1 / avg_players))
            push!(players_winrate, p => (winrate, Float16(-log(score)), avg_players))
        catch Exception
            println("Error $p with $winrate")
        end

        l = length(players_winrate)
        top5 = sort(collect(players_winrate), by=x -> -x[2][2])[1:min(5, l)]

        top5_str = ""
        for (i, x) in enumerate(top5)
            top5_str *= "\n\t$i. $(x[1]) ($(x[2][1]), $(x[2][2]), $(x[2][3])) "
        end

        println("Players calulate/seen: $l/$(length(seen))\nTop 5: (p100, score, avg ppl)) $top5_str")
    end
end






get_players()
