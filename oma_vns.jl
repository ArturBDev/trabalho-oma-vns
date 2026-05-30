#!/usr/bin/env julia

using Random
using Printf

# Tabela de Melhores Valores Conhecidos (BKV) fornecidos pelo professor
const BKV = Dict(
    "oma01.dat" => 472.0, "oma02.dat" => 474.0, "oma03.dat" => 470.0,
    "oma04.dat" => 470.0, "oma05.dat" => 474.0, "oma06.dat" => 719.0,
    "oma07.dat" => 724.0, "oma08.dat" => 732.0, "oma09.dat" => 733.0,
    "oma10.dat" => 721.0
)

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

# --- PROCESSAMENTO EM LOTE (5 SEMENTES) ---

function processar_pasta(pasta)
    arquivos = filter(x -> endswith(x, ".dat") && startswith(x, "oma"), readdir(pasta))
    sort!(arquivos)
    
    TIME_LIMIT = 300.0 
    NUM_SEEDS = 5
    
    resultados = []

    println("Iniciando bateria de testes do VNS (Julia)...")
    println("Time limit por seed: ", TIME_LIMIT, " seg | Sementes: ", NUM_SEEDS)
    
    for arquivo in arquivos
        caminho = joinpath(pasta, arquivo)
        print(">> Processando ", arquivo, " ... ")
        
        texto = read(caminho, String)
        tokens = split(texto)
        valores = parse.(Float64, tokens)
        
        n = round(Int, valores[1])
        m_size = round(Int, valores[2])
        
        A = zeros(Float64, n, n)
        
        # CORREÇÃO CHAVE: Lendo como Lista de Arestas (u, v, peso)
        idx = 3
        while idx + 2 <= length(valores)
            u = round(Int, valores[idx])
            v = round(Int, valores[idx+1])
            peso = valores[idx+2]
            
            # Preenche espelhando para garantir matriz perfeitamente simétrica
            if 1 <= u <= n && 1 <= v <= n
                A[u, v] = peso
                A[v, u] = peso
            end
            
            idx += 3 # Avança de 3 em 3 (Próxima Aresta)
        end

        S_init, _ = greedy_initial_solution(n, m_size, A)
        aff_inicial = get_total_affinity(S_init, A)

        soma_aff = 0.0
        soma_time = 0.0

        for seed in 1:NUM_SEEDS
            Random.seed!(seed * 1000) 
            _, aff_final, exec_time = run_vns(n, m_size, A, TIME_LIMIT)
            soma_aff += aff_final
            soma_time += exec_time
        end

        media_aff = soma_aff / NUM_SEEDS
        media_time = soma_time / NUM_SEEDS
        
        bkv = get(BKV, arquivo, NaN)
        desvio_si = 100 * (aff_inicial - media_aff) / aff_inicial
        desvio_opt = 100 * (bkv - media_aff) / bkv

        push!(resultados, (arquivo, aff_inicial, media_aff, desvio_si, desvio_opt, media_time))
        println("Concluído!")
    end

    println("\n\n" * "="^100)
    println(" TABELA DE RESULTADOS COMPUTACIONAIS - META-HEURÍSTICA VNS (JULIA) ")
    println("="^100)
    @printf("%-12s | %-12s | %-12s | %-12s | %-12s | %-12s\n", 
            "Instância", "Val. Inicial", "Valor Final", "Desvio (SI)", "Desvio (Opt)", "Tempo VNS(s)")
    println("-"^100)
    
    for r in resultados
        @printf("%-12s | %-12.2f | %-12.2f | %-11.2f%% | %-11.2f%% | %-12.2f\n", r...)
    end
    println("="^100)
end

pasta_alvo = length(ARGS) > 0 ? first(ARGS) : "."
processar_pasta(pasta_alvo)