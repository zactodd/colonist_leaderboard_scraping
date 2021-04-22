using HTTP, Gumbo, Cascadia, Dates, JSON, KissThreading

PROFILE_URL = "https://colonist.io/api/profile" #"https://colonist.io/profile"
COOKIE = "ga=GA1.2.456225344.1599180098; Indicative_a38719f2-d919-446b-b2e3-0da55a22a29a=\"%7B%22defaultUniqueID%22%3A%22dda3b884-9719-44c7-8a3f-0e58b3cee020%22%7D\"; __qca=P0-58763845-1599180099331; __stripe_mid=db19d11e-0bcf-4b6f-9159-ecd3accd3ccb282899; __cfduid=d059248e9acf639da6354e2915de014461617867544; _gid=GA1.2.1696456463.1618990930; jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiIyNTIxNTE4IiwiaWF0IjoxNjE5MDkyODc1LCJleHAiOjE2MjE2ODQ4NzUsImF1ZCI6ImNvbG9uaXN0LmlvIiwiaXNzIjoiY29sb25pc3QuaW8ifQ.i0BoKkIpd1sFRSfg-5xBFBUakDK2Cdoj2DOknKgpKqA"


user_url(user) = "$PROFILE_URL/$user"
info_from_url(url, headers) = HTTP.request("GET", url, headers=headers).body |> String |> JSON.parse
user_info(user) = info_from_url(user_url(user), ["cookie" => COOKIE])


binomial_prob(x::BigInt, p::BigFloat, n::BigInt) = binomial(n, x) * (p ^ x) * ((1 - p) ^ (n - x))
binomial_prob_sum_100(x::BigInt, p::BigFloat) = sum(map(i -> binomial_prob(i, p, BigInt(100)), 1:x))
neg_log_binimal_prob(winrate, p) = -log(1 - binomial_prob_sum_100(BigInt(winrate), BigFloat(1 / p)))


function get_players(start_user="ZacTodd")
    players_winrate = Dict()
    seen = Set([start_user])
    q = Set([start_user])
    while length(q) != 0
        players = map(x -> pop!(q), 1:min(Threads.nthreads(), length(q)))
        players_evals = tmap(p -> eval_player_info(p, seen), players)

        for (p, (new_players, score)) in zip(players, players_evals)
            if !ismissing(score) push!(players_winrate, p => score) end
            for np in new_players
                push!(seen, np)
                push!(q, np)
            end

        end

        l = length(players_winrate)
        top = sort(collect(players_winrate), by=x -> -x[2][2])[1:min(30, l)]
        top = join(map(x -> "\t$(x[1]). $(x[2][1]) ($(join(x[2][2], ", ")))", enumerate(top)), "\n")
        println("Players eval/seen: $l/$(length(seen))\nTop 30: (p100, score, avg ppl)) \n$top")
    end
end


function metrics_winrate_score_avg_player(winrate, num_players_list)
    try
        avg_players = sum(num_players_list) / length(num_players_list)
        score = Float16(neg_log_binimal_prob(winrate, avg_players))
        return winrate, score, avg_players
    catch Exception
        println("Error $p with $winrate $Exception")
        return winrate, 0, 0
    end
end


function eval_player_info(player_name, seen_players)
    player_info = try user_info(player_name) catch Exception return [], missing end
    has_bot_games = false
    num_players_list = []

    new_players = Set()
    for g in player_info["gameDatas"]
        append!(num_players_list, length(g["players"]))
        for op in g["players"]
            username = op["username"]
            if !occursin("#", username) && !(username in seen_players)
                push!(new_players, username)
            end
            if username == "Bot" has_bot_games = true end
        end
    end

    if has_bot_games
        score = missing
    else
        winrate = player_info["winsInLast100Games"]
        score = metrics_winrate_score_avg_player(winrate, num_players_list)
    end
    return new_players, score
end


println("Startng")
get_players()