#!/usr/bin/env julia

using JuMP
using GLPK
using Printf

function resolver_todas_instancias(pasta)
    # Procura todos os arquivos .dat que começam com "oma" na pasta fornecida
    arquivos = filter(x -> endswith(x, ".dat") && startswith(x, "oma"), readdir(pasta))
    sort!(arquivos) # Garante que vai rodar em ordem (oma01, oma02, etc.)

    if isempty(arquivos)
        println("Nenhuma instância .dat encontrada na pasta: $pasta")
        return
    end

    resultados = []

    for arquivo in arquivos
        caminho_completo = joinpath(pasta, arquivo)
        println("\n>>> Processando: $arquivo ...")
        
        # Leitura da Instância
        texto = read(caminho_completo, String)
        tokens = split(texto)
        valores = parse.(Float64, tokens)
        
        n = round(Int, valores[1])
        m_size = round(Int, valores[2])
        
        A = zeros(Float64, n, n)
        idx = 3
        for i in 1:n
            for j in 1:n
                A[i,j] = valores[idx]
                idx += 1
            end
        end

        # Criação do Modelo
        modelo = Model(GLPK.Optimizer)
        
        # Desliga as mensagens gigantes do solver na tela para ficar limpo
        set_silent(modelo)
        
        # Limite de tempo de 25 minutos (1500 segundos) para não travar o PC
        set_time_limit_sec(modelo, 1500.0)

        @variable(modelo, x[1:n], Bin)
        @variable(modelo, y[i=1:n, j=(i+1):n], Bin)

        @objective(modelo, Max, sum(A[i,j] * y[i,j] for i=1:n, j=(i+1):n))

        @constraint(modelo, sum(x[i] for i=1:n) == m_size)
        @constraint(modelo, [i=1:n, j=(i+1):n], y[i,j] <= x[i])
        @constraint(modelo, [i=1:n, j=(i+1):n], y[i,j] <= x[j])

        # Resolve e cronometra o tempo exato (em segundos)
        tempo_execucao = @elapsed optimize!(modelo)
        status = termination_status(modelo)

        # Salva os resultados para a tabela
        if status == MOI.OPTIMAL
            z_opt = objective_value(modelo)
            push!(resultados, (arquivo, n, m_size, z_opt, tempo_execucao, "Ótimo"))
            println("Concluído! Status: Ótimo | Afinidade: $z_opt")
            
        elseif status == MOI.TIME_LIMIT
            # Se estourar o tempo, tenta pegar a melhor resposta encontrada até o momento
            z_opt = has_values(modelo) ? objective_value(modelo) : NaN
            push!(resultados, (arquivo, n, m_size, z_opt, tempo_execucao, "Limite de Tempo"))
            println("Concluído! Status: Limite de Tempo atingido.")
            
        else
            push!(resultados, (arquivo, n, m_size, NaN, tempo_execucao, string(status)))
            println("Concluído! Status: $status")
        end
    end

    # =========================================================================
    # GERAÇÃO DA TABELA FINAL PARA O RELATÓRIO
    # =========================================================================
    println("\n\n" * "="^75)
    println(" RESUMO DOS RESULTADOS - SOLVER EXATO (GLPK) ")
    println("="^75)
    @printf("%-12s | %-4s | %-4s | %-12s | %-12s | %-15s\n", "Instância", "n", "m", "Afinidade", "Tempo (s)", "Status")
    println("-"^75)
    
    for r in resultados
        if isnan(r[3])
            @printf("%-12s | %-4d | %-4d | %-12s | %-12.2f | %-15s\n", r[1], r[2], r[4], "-", r[5], r[6])
        else
            @printf("%-12s | %-4d | %-4d | %-12.2f | %-12.2f | %-15s\n", r[1], r[2], r[4], r[3], r[5], r[6])
        end
    end
    println("="^75)
    println("Copie esses dados para a tabela de resultados computacionais do relatório.")
end

# Se passar a pasta por argumento, usa ela; senão, usa a pasta atual (".")
pasta_alvo = length(ARGS) > 0 ? ARGS[1] : "."
resolver_todas_instancias(pasta_alvo)