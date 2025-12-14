%% Hager %%
%Items sold in the supermarket
% item(item,price,weight,category)

item(milk,20,1000,food).
item(bread,15,400,food).
item(apple,5,variable,fruits).
item(banana,4,variable,fruits).
item(chips,10,150, snack).
item(chocolate,12,120,snack).
item(soap,18,250,cleaning).
item(wine,150,750,alcohol).
item(beer,45,330, alcohol).
item(vodka,220,500, alcohol).

%Age restricted items
age_restricted(wine).
age_restricted(beer).
age_restricted(vodka).


stock(milk,5).
stock(bread,7).
stock(apple,30).
stock(banana,25).
stock(chips,10).
stock(chocolate,6).
stock(soap,8).
stock(wine,3).
stock(beer,12).
stock(vodka,4).


%taxes on sold stocks
tax_rate(food,0.05).
tax_rate(fruits,0.00).
tax_rate(snack,0.10).
tax_rate(cleaning,0.14).
tax_rate(alcohol,0.20).

% attendant(ID, Role).
attendant(aat1, attendant).
attendant(aat2, admin).
attendant(aat3, admin).

admin_authorized(ID) :- attendant(ID, admin).

% loyalty(CardID, Points).
loyalty(card_alex, 450).
loyalty(card_sara, 1200).
loyalty(card_tom, 2500).

% Tier thresholds and percentage discount
% tier(Name, MinPoints, MaxPoints, DiscountPercent).
tier(bronze, 0, 499, 0).
tier(silver, 500, 1999, 2).
tier(gold,   2000, 999999, 5).

%pay(Method)
pay(cash).
pay(card).
pay(e-wallet).


%% Ebrahim %%
%  VERIFY AGE
action(verify_age(Admin),
       state(B,T,Sens,age_check_needed,L,Stock),
       state(B,T,Sens,none,L,Stock)) :-
    admin_authorized(Admin).

%  CALCULATE TOTAL
action(calculate_total,
       state(B,T,Sens,none,L,Stock),
       state(B,FinalTotal,Sens,none,L,Stock)) :-

    calc_tax(B, TaxValue),
    Subtotal is T + TaxValue,
     FinalTotal = Subtotal.


%% Anas %%
%% Responsibility:
%% 1. Scan items and update basket & stock
%% 2. Remove items from basket and restore stock
%% 3. Ensure stock availability before any scan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% stock_check/3
%% stock_check(Item, StockIn, StockOut)
%% - Verifies that the item exists in stock
%% - Decreases stock quantity by 1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


stock_check(Item, StockIn, StockOut) :-
    select(stock(Item, Count), StockIn, Rest),
    Count > 0,                       % Ensure item is available
    NewCount is Count - 1,
    StockOut = [stock(Item, NewCount) | Rest].



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% action(scan/1) - Normal items (NOT age restricted)
%% Adds item to basket, updates total price, and decreases stock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


action(scan(Item),
    state(Basket, Total, none, Loyalty, StockIn, PaymentStatus),
    state([item(Item, Price, Weight) | Basket],
          NewTotal,
          none,
          Loyalty,
          StockOut,
          PaymentStatus)
) :-
    item(Item, Price, Weight, _),     % Item exists in database
    \+ age_restricted(Item),          % Item is NOT age restricted
    stock_check(Item, StockIn, StockOut),
    NewTotal is Total + Price.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% action(scan/1) - Age restricted items
%% Scans item, updates stock and total,
%% but blocks the system until admin verification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


action(scan(Item),
    state(Basket, Total, none, Loyalty, StockIn, PaymentStatus),
    state([item(Item, Price, Weight) | Basket],
          NewTotal,
          age_check_needed,
          Loyalty,
          StockOut,
          PaymentStatus)
) :-
    item(Item, Price, Weight, _),     % Item exists in database
    age_restricted(Item),             % Item requires age verification
    stock_check(Item, StockIn, StockOut),
    NewTotal is Total + Price.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% action(remove/1)
%% Removes item from basket and restores it to stock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

action(remove(Item),
    state(Basket, Total, BlockedStatus, Loyalty, StockIn, PaymentStatus),
    state(NewBasket,
          NewTotal,
          BlockedStatus,
          Loyalty,
          StockOut,
          PaymentStatus)
) :-
    select(item(Item, Price, Weight), Basket, NewBasket), % Remove item from basket
    select(stock(Item, Count), StockIn, Rest),
    NewCount is Count + 1,                                % Restore stock
    StockOut = [stock(Item, NewCount) | Rest],
    NewTotal is Total - Price.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Mohamed – Financials & Payment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Calculate tax
calc_tax([], 0).
calc_tax([item(Item, Price, _)|Rest], TotalTax) :-
    item(Item, _, _, Category),
    tax_rate(Category, Rate),
    ItemTax is Price * Rate,
    calc_tax(Rest, RestTax),
    TotalTax is ItemTax + RestTax.

% Loyalty discount
loyalty_discount(no_card, _, 0).
loyalty_discount(card(CardID, Points), SubTotal, Discount) :-
    loyalty(CardID, Points),
    tier(_, Min, Max, Percent),
    Points >= Min,
    Points =< Max,
    Discount is SubTotal * (Percent / 100).

% Calculate final total
action(calculate_total,
    state(Basket, Total, none, Loyalty, Stock, pending),
    state(Basket, FinalTotal, none, Loyalty, Stock, pending)
) :-
    Basket \= [],
    calc_tax(Basket, Tax),
    SubTotal is Total + Tax,
    loyalty_discount(Loyalty, SubTotal, Discount),
    FinalTotal is SubTotal - Discount.

% Pay
action(pay(Method),
    state(B,T,none,L,S,pending),
    state(B,T,none,L,S,completed)
) :-
    pay(Method).

% Print receipt
action(print_receipt,
    state(Basket, Total, none, Loyalty, _, completed),
    state(Basket, Total, none, Loyalty, _, completed)
) :-
    nl,
    write('========= RECEIPT ========='), nl,
    print_items(Basket),
    write('Loyalty: '), write(Loyalty), nl,
    write('Total Paid: '), write(Total), nl,
    write('Payment Status: COMPLETED'), nl,
    write('==========================='), nl.

print_items([]).
print_items([item(Item, Price, _)|Rest]) :-
    write('- '), write(Item), write(' : '), write(Price), nl,
    print_items(Rest).

goal_state(state(Basket, FinalTotal, none, _, _, completed)) :-
    Basket \= [],
    FinalTotal > 0.

%% =====================================================
%% Shahd %%
%% Responsibility: Variable-weight (Non-barcoded) items
%% Handles fruits priced per kilogram
%% =====================================================

action(weigh_produce(Item, Weight),
       state(Basket, Total, none, Loyalty, StockIn, PaymentStatus),
       state(NewBasket, NewTotal, none, Loyalty, StockOut, PaymentStatus)) :-

    % Ensure the item is a variable-priced fruit
    item(Item, PricePerKg, variable, fruits),

    % Calculate price based on weight (grams to kilograms)
    NewPrice is PricePerKg * (Weight / 1000),

    % Update total cost
    NewTotal is Total + NewPrice,

    % Add the weighed item (with calculated price) to the basket
    NewBasket = [item(Item, NewPrice, Weight) | Basket],

    % Decrease stock by one unit for each weighing operation
    stock_check(Item, StockIn, StockOut).