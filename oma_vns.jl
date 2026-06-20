#!/usr/bin/env julia
using Random

### --- FUNÇÕES AUXILIARES ---
function calc_delta(S, A, i_out, j_in) 
    delta = 0.0 
    for p in S 
        if p != i_out 
            delta += A[j_in, p] - A[i_out, p] 
        end 
    end 
    return delta 
end

function get_total_affinity(S, A) 
    aff = 0.0 
    for i in 1:length(S) 
        for j in (i+1):length(S) 
            aff += A[S[i], S[j]] 
        end 
    end 
    return aff 
end

### --- VNS: ETAPAS DA PROPOSTA ---
function greedy_initial_solution(n, m, A) 
    max_aff = -1.0 
    best_pair = (1, 2)
    
    # 1º Passo: Aresta com maior afinidade absoluta
    for i in 1:n
        for j in i+1:n
            if A[i,j] > max_aff
                max_aff = A[i,j]
                best_pair = (i, j)
            end
        end
    end
    
    S = Int[best_pair[1], best_pair[2]]
    in_S = falses(n)
    in_S[best_pair[1]] = true
    in_S[best_pair[2]] = true
    
    # 2º Passo: Adiciona quem tem maior ganho marginal
    while length(S) < m
        best_cand = -1
        best_inc = -1.0
        for i in 1:n
            if !in_S[i]
                inc = 0.0
                for v in S
                    inc += A[i, v]
                end
                if inc > best_inc
                    best_inc = inc
                    best_cand = i
                end
            end
        end
        push!(S, best_cand)
        in_S[best_cand] = true
    end
    return S, in_S
end

function local_search_n1(n, m, A, S, in_S, start_time, time_limit) 
    improved = true 
    while improved && (time() - start_time) < time_limit 
        improved = false 
        for i_idx in 1:length(S) 
            i_out = S[i_idx] 
            for j_in in 1:n 
                if !in_S[j_in] 
                    delta = calc_delta(S, A, i_out, j_in) 
                    if delta > 1e-5 
                        S[i_idx] = j_in 
                        in_S[i_out] = false 
                        in_S[j_in] = true 
                        improved = true 
                        break 
                    end 
                end 
            end 
            if improved 
                break 
            end 
        end 
    end 
    return S, in_S 
end

function run_vns(n, m, A, time_limit, limite_estagnacao, fator_kmax) 
    start_time = time()
    
    S, in_S = greedy_initial_solution(n, m, A)
    best_S = copy(S)
    best_aff = get_total_affinity(S, A)
    init_aff = best_aff
    
    # Fator adaptativo passado via ARGS
    k_max = max(2, ceil(Int, m / fator_kmax))
    k = 2
    estagnacao = 0
    
    while (time() - start_time) < time_limit && estagnacao < limite_estagnacao
        # Shaking k-k
        S_shake = copy(best_S)
        in_S_shake = copy(in_S)
        
        out_S = Int[]
        for i in 1:n
            if !in_S_shake[i]
                push!(out_S, i)
            end
        end
        
        shuffle!(S_shake)
        shuffle!(out_S)
        
        for i in 1:k
            v_out = S_shake[i]
            v_in = out_S[i]
            S_shake[i] = v_in
            in_S_shake[v_out] = false
            in_S_shake[v_in] = true
        end
        
        # Busca Local 
        S_novo, in_S_novo = local_search_n1(n, m, A, S_shake, in_S_shake, start_time, time_limit)
        aff_novo = get_total_affinity(S_novo, A)
        
        if aff_novo > best_aff + 1e-5
            best_S = copy(S_novo)
            in_S = copy(in_S_novo)
            best_aff = aff_novo
            k = 2
            estagnacao = 0
        else
            k += 1
            if k > k_max
                k = 2
            end
            estagnacao += 1
        end
    end
    
    el_time = time() - start_time
    return init_aff, best_aff, best_S, el_time
end

### --- FUNÇÃO PRINCIPAL EXIGIDA PELO TRABALHO ---
function main() 
    # Verifica regras de linha de comando adaptadas
    if length(ARGS) < 2 
        println(stderr, "Uso incorreto. Execute: julia oma_vns.jl <arquivo_saida> <tempo_limite> [estagnacao] [fator_kmax]") 
        exit(1) 
    end
    
    arquivo_saida = ARGS[1]
    time_limit = parse(Float64, ARGS[2])
    
    # Novos parâmetros de calibração para testes (Se o usuário não passar, usa os ótimos do relatório)
    limite_estagnacao = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 500
    fator_kmax = length(ARGS) >= 4 ? parse(Int, ARGS[4]) : 4
    
    # Leitura da Instância puramente por STDIN
    linhas = readlines(stdin)
    if isempty(linhas) return end
    
    primeira_linha = split(linhas[1])
    n = parse(Int, primeira_linha[1])
    m = parse(Int, primeira_linha[2])
    
    A = zeros(Float64, n, n)
    for i in 2:length(linhas)
        linha = split(linhas[i])
        if length(linha) >= 3
            u = parse(Int, linha[1]) + 1
            v = parse(Int, linha[2]) + 1
            af = parse(Float64, linha[3])
            A[u, v] = af
            A[v, u] = af
        end
    end
    
    # 5 Repetições com Seeds distintas exigidas nas normas
    NUM_SEEDS = 5
    sum_si = 0.0
    sum_sf = 0.0
    sum_time = 0.0
    melhor_global = -1.0
    melhor_S_global = Int[]
    
    for seed in 1:NUM_SEEDS
        Random.seed!(seed * 1000)
        
        # Chama a função run_vns que estava na sua estrutura inicial
        init_aff, best_aff, best_S, el_time = run_vns(n, m, A, time_limit, limite_estagnacao, fator_kmax)
        
        sum_si += init_aff
        sum_sf += best_aff
        sum_time += el_time
        
        if best_aff > melhor_global
            melhor_global = best_aff
            melhor_S_global = copy(best_S)
        end
    end
    
    avg_sf = sum_sf / NUM_SEEDS
    
    open(arquivo_saida, "w") do io
        println(io, "Instância de Tamanho N: ", n, " M: ", m)
        println(io, "Valor Inicial (Média): ", round(sum_si / NUM_SEEDS, digits=2))
        println(io, "Valor Final (Média): ", round(avg_sf, digits=2))
        println(io, "Tempo CPU (Média s): ", round(sum_time / NUM_SEEDS, digits=4))
        println(io, "--------------------------------------------------")
        println(io, "Melhor Grupo Encontrado: ", sort(melhor_S_global .- 1)) 
    end
    
    # Impressão na saída padrão exigida pelo critério de avaliação
    println(round(avg_sf, digits=2))
end

main()