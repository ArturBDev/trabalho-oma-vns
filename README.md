# Otimização Combinatória: Problema "Os Melhores Amigos" (OMA)

Este repositório contém o trabalho prático desenvolvido para a disciplina de Otimização Combinatória. O objetivo é resolver o problema de seleção de subconjunto com máxima afinidade, utilizando tanto métodos exatos quanto meta-heurísticas.

## 📝 O Problema: Os Melhores Amigos

O problema consiste em selecionar um grupo de $m$ pessoas a partir de um conjunto $P$ de $n$ candidatos, de forma a maximizar a afinidade total do grupo.

- **Instância:** Um conjunto de $n$ pessoas $P = \{1, \dots, n\}$, valores de afinidade $a_{ij} \ge 0$ para cada par $\{i, j\}$ ($i < j$), e um inteiro $m$.
- **Solução:** Um subconjunto $S \subseteq P$ com exatamente $|S| = m$.
- **Objetivo:** Maximizar a afinidade total $A(S) = \sum_{\{i,j\} \subseteq S} a_{ij}$.

## ⚖️ Formulação Matemática (PLI)

O problema foi formulado como um Programa Linear Inteiro (PLI) da seguinte forma:

**Variáveis de Decisão:**

- $x_i \in \{0, 1\}$: 1 se a pessoa $i$ for selecionada para o grupo, 0 caso contrário.
- $y_{ij} \in \{0, 1\}$: 1 se ambas as pessoas $i$ e $j$ forem selecionadas, 0 caso contrário.

**Função Objetivo:**
$$\text{Maximizar } \sum_{i=1}^{n} \sum_{j=i+1}^{n} a_{ij} \cdot y_{ij}$$

**Restrições:**

1. Selecionar exatamente $m$ pessoas:
   $$\sum_{i=1}^{n} x_i = m$$
2. Garantir que $y_{ij}$ seja 1 apenas se $x_i$ e $x_j$ forem 1:
   $$y_{ij} \le x_i, \quad \forall i, j: i < j$$
   $$y_{ij} \le x_j, \quad \forall i, j: i < j$$
3. Domínio das variáveis:
   $$x_i, y_{ij} \in \{0, 1\}$$

## 🚀 Implementação e Métodos

O projeto foi desenvolvido em **Julia**, utilizando as seguintes abordagens:

### 1. Solver Exato (`solver.jl`)

Utiliza a biblioteca **JuMP** com o solver **GLPK** para resolver a formulação de programação inteira. Este script processa as instâncias e busca a solução ótima global (ou a melhor possível dentro do limite de tempo).

### 2. Meta-heurística VNS (`oma_vns.jl`)

Implementação da busca **Variable Neighborhood Search (VNS)** para encontrar soluções de alta qualidade em tempos reduzidos. As etapas incluem:

- **Solução Inicial:** Construção gulosa baseada na maior afinidade acumulada.
- **Busca Local:** Troca de elementos (1-swap) para melhoria da solução.
- **Shaking:** Perturbação da solução trocando $k$ elementos aleatórios para escapar de ótimos locais.

## 📊 Instâncias e BKVs (Best Known Values)

As instâncias utilizadas (`oma01` a `oma10`) possuem os seguintes melhores valores conhecidos:

| Instância | BKV | Instância | BKV |
| --------- | --- | --------- | --- |
| oma01     | 472 | oma06     | 719 |
| oma02     | 474 | oma07     | 724 |
| oma03     | 470 | oma08     | 732 |
| oma04     | 470 | oma09     | 733 |
| oma05     | 474 | oma10     | 721 |

## 🛠️ Requisitos e Como Executar

### Pré-requisitos

- [Julia](https://julialang.org/) instalado.
- Pacotes necessários: `JuMP`, `GLPK`, `Random`, `Printf`.
  - Para instalar: `julia -e 'using Pkg; Pkg.add(["JuMP", "GLPK"])'`

### Executando o Solver Exato

```bash
julia solver.jl
```

### Executando a Meta-heurística VNS

```bash
julia oma_vns.jl
```

## 👥 Integrantes

- Artur Santos
- Lucca Claus

---

_Este projeto faz parte da avaliação da disciplina de Otimização Combinatória._
