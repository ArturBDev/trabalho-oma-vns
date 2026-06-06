#!/usr/bin/env julia

using Random

# --- FUNÇÕES AUXILIARES ---

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

# --- VNS: ETAPAS DA PROPOSTA ---

function greedy_initial_solution(n, m, A)
    max_aff = -1.0
    best_pair = (1, 2)
    
    for i in 1:n
        for j in (i+1):n
            if A[i,j] > max_aff
                max_aff = A[i,j]
                best_pair = (i, j)
            end
        end
    end

    S = [first(best_pair), last(best_pair)]
    in_S = falses(n)
    in_S[first(best_pair)] = true
    in_S[last(best_pair)] = true

    while length(S) < m
        best_p = -1
        max_sum = -Inf
        for p in 1:n
            if !in_S[p]
                current_sum = sum(A[p, v] for v in S)
                if current_sum > max_sum
                    max_sum = current_sum
                    best_p = p
                end
            end
        end
        push!(S, best_p)
        in_S[best_p] = true
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

function run_vns(n, m, A, time_limit)
    start_time = time()
    
    S, in_S = greedy_initial_solution(n, m, A)
    S, in_S = local_search_n1(n, m, A, S, in_S, start_time, time_limit)

    best_S = copy(S)
    best_aff = get_total_affinity(S, A)

    k_max = max(2, ceil(Int, m / 4.0))
    iter_without_improvement = 0
    max_iters = 500  

    while (time() - start_time) < time_limit && iter_without_improvement < max_iters
        k = 2
        while k <= k_max && (time() - start_time) < time_limit
            curr_S = copy(best_S)
            curr_in_S = falses(n)
            for p in curr_S; curr_in_S[p] = true; end

            out_candidates = shuffle(curr_S)[begin:k]
            p_minus_s = [p for p in 1:n if !curr_in_S[p]]
            in_candidates = shuffle(p_minus_s)[begin:k]

            for i in 1:k
                idx_out = findfirst(==(out_candidates[i]), curr_S)
                curr_S[idx_out] = in_candidates[i]
                curr_in_S[out_candidates[i]] = false
                curr_in_S[in_candidates[i]] = true
            end

            curr_S, curr_in_S = local_search_n1(n, m, A, curr_S, curr_in_S, start_time, time_limit)
            curr_aff = get_total_affinity(curr_S, A)

            if curr_aff > (best_aff + 1e-5)
                best_S = copy(curr_S)
                best_aff = curr_aff
                k = 2
                iter_without_improvement = 0
            else
                k += 1
            end
        end
        iter_without_improvement += 1
    end
    return best_S, best_aff, (time() - start_time)
end

# --- FUNÇÃO PRINCIPAL EXIGIDA PELO TRABALHO ---

function main()
    # Verifica regras de linha de comando
    if length(ARGS) < 1
        println(stderr, "Uso incorreto. O primeiro parametro deve ser o arquivo de saida.")
        exit(1)
    end
    
    arquivo_saida = first(ARGS)
    
    # Segundo parametro opcional: tempo limite em segundos (se não passar, usa 300)
    time_limit = length(ARGS) >= 2 ? parse(Float64, ARGS[begin+1]) : 300.0

    # Lendo arquivo da entrada padrão (stdin)
    texto = read(stdin, String)
    tokens = split(texto)
    if isempty(tokens)
        return
    end

    n = round(Int, parse(Float64, first(tokens)))
    m_size = round(Int, parse(Float64, tokens[begin+1]))
    
    A = zeros(Float64, n, n)
    idx = 3
    while idx + 2 <= length(tokens)
        # Ajuste para base-1 do Julia, pois as instâncias do professor começam com a pessoa 0
        u = round(Int, parse(Float64, tokens[idx])) + 1
        v = round(Int, parse(Float64, tokens[idx+1])) + 1
        peso = parse(Float64, tokens[idx+2])
        
        if 1 <= u <= n && 1 <= v <= n
            A[u, v] = peso
            A[v, u] = peso
        end
        idx += 3
    end

    # Executa a meta-heurística
    best_S, best_aff, _ = run_vns(n, m_size, A, time_limit)

    # Subtrai 1 para voltar os IDs ao formato base-0 original da especificação
    solucao_final = sort([p - 1 for p in best_S])
    str_solucao = join(solucao_final, " ")

    # 1. Imprime a melhor solução encontrada na saída padrão (stdout)
    println(str_solucao)

    # 2. Grava a melhor solução encontrada no arquivo passado por parâmetro
    open(arquivo_saida, "w") do f
        println(f, str_solucao)
    end
end

main()