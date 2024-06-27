-module(prodcons).
-export([start/0, producer/1, consumer/1, consume/2]).
start() ->
    %% Iniciar produtores e registrá-los
    P1 = spawn(fun() -> producer(1) end),
    register(producer1, P1),
    P2 = spawn(fun() -> producer(2) end),
    register(producer2, P2),
    %% Iniciar consumidores
    spawn(fun() -> consumer(1) end),
    spawn(fun() -> consumer(2) end),
    spawn(fun() -> consumer(3) end),
    spawn(fun() -> consumer(4) end),
    %% Monitorar produtores
    erlang:monitor(process, P1),
    erlang:monitor(process, P2).
producer(Id) ->
    loop(Id, []).
loop(Id, Queue) ->
    %% Se a fila estiver vazia, começar a produção de um novo produto
    case Queue of
        [] ->
            ProductType = rand:uniform(2),
            ProductionTime = case ProductType of
                1 -> 3.5;  %% Tempo de produção para o tipo de produto 1
                2 -> 7.5  %% Tempo de produção para o tipo de produto 2
            end,
            NewProduct = {Id, ProductType},  %% Produzir aleatoriamente tipo 1 ou 2
            io:format("Produtor ~p: INICIANDO PRODUÇÃO PRODUTO ~p~n", [Id, ProductType]),
            timer:sleep(trunc(ProductionTime * 1000)),  %% Simular tempo de produção
            io:format("Produtor ~p: PRODUTO FINALIZADO ~p~n", [Id, ProductType]),
            loop(Id, Queue ++ [NewProduct]);
        _ ->
            loop_after_production(Id, Queue)
    end.
loop_after_production(Id, Queue) ->
    receive
        done ->
            io:format("Produtor ~p: PRODUTOR CANSADO~n", [Id]),
            loop(Id, Queue);

        {consume, ConsumerPid} when length(Queue) > 0 ->
            [Product | Rest] = Queue,
            ConsumerPid ! {produce, Product},
            loop(Id, Rest)
    end.
consumer(Id) ->
    loop_consume(Id).
loop_consume(Id) ->
    %% Solicitar produto dos produtores
    P1 = whereis(producer1),
    P2 = whereis(producer2),
    case rand:uniform(2) of
        1 -> P1 ! {consume, self()};
        2 -> P2 ! {consume, self()}
    end,
    receive
        {produce, Product} ->
            consume(Id, Product),
            loop_consume(Id)
    end.
consume(Id, {PId, Type}) ->
    ConsumptionTime = case Type of
        1 -> 7.0;  %% Tempo de consumo para o tipo de produto 1 (2 * 3.5)
        2 -> 15.0  %% Tempo de consumo para o tipo de produto 2 (2 * 7.5)
    end,
    io:format("Consumidor ~p: Consumindo o produto ~p do produtor ~p~n", [Id, Type, PId]),
    timer:sleep(trunc(ConsumptionTime * 1000)),  %% Converter para milissegundos
    io:format("Consumidor ~p: Terminei de consumir o produto ~p~n", [Id, Type]).
