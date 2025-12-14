:- discontiguous action/3.   % Allows action clauses to be spread out
:- style_check(-singleton).  % Suppresses singleton variable warnings

%% Hagar %%

%Items sold in the supermarket
% item(item,price,weight,category)

item(milk,20,1000,food).
item(bread,15,400,food).
item(apple,5,variable,fruits).
item(banana,4,variable,fruits).
item(chips,10,150, snack).
item(chocolate,12,120,snack).
item(soap,18,250,cleaning).
item(cigarettes,85,200,tobacco).
item(rolling_tobacco,120,150,tobacco).
item(cigar_pack,250,300,tobacco).
%Age restricted items
age_restricted(cigarettes).
age_restricted(rolling_tobacco).
age_restricted(cigar_pack).
%Initial stock levels
stock(milk,5).
stock(bread,7).
stock(apple,30).
stock(banana,25).
stock(chips,10).
stock(chocolate,6).
stock(soap,8).
stock(cigarettes, 10).
stock(rolling_tobacco, 5).
stock(cigar_pack, 3).
%taxes on sold stocks
tax_rate(food,0.05).
tax_rate(fruits,0.00).
tax_rate(snack,0.10).
tax_rate(cleaning,0.14).
tax_rate(tobacco,0.30).
% attendant roles
% attendant(ID, Role).
attendant(aat1, attendant).
attendant(aat2, admin).
attendant(aat3, admin).

admin_authorized(ID) :- attendant(ID, admin).
% Loyalty program
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
% Initial state
initial_state(state([], 0, none, no_card, InitialStock, pending)) :-
    findall(stock(Item, Count), stock(Item, Count), InitialStock).
%% Ebrahim %%
%  VERIFY AGE

/* state(Basket, Total, none, Loyalty, StockIn, PaymentStatus),
    state([item(Item, Price, Weight) | Basket],
  */

% Define legal age
legal_age(18).

% Action now takes a number (CustomerAge) instead of an Admin ID
action(verify_age(CustomerAge),
       state(Basket, Total, age_check_needed, Loyalty, Stock, PaymentStatus),
       state(Basket, Total, none,             Loyalty, Stock, PaymentStatus)) :-
    legal_age(Limit),
    CustomerAge >= Limit.     % <--- Now it checks the number!

%  CALCULATE TOTAL
/*
action(calculate_total,
       state(B,T,Sens,none,L,Stock),
       state(B,FinalTotal,Sens,none,L,Stock)) :-

    calc_tax(B, TaxValue),
    Subtotal is T + TaxValue,
     FinalTotal = Subtotal.
*/
%% Anas %%
% Helper predicate to check and update stock
%% Anas %%

% Helper predicate to check and update stock
stock_check(Item, StockIn, StockOut) :-
    select(stock(Item, Count), StockIn, Rest),
    Count > 0,                        % Ensure item is available
    NewCount is Count - 1,
    StockOut = [stock(Item, NewCount) | Rest].

% ---------------------------------------------------------
% SCAN ACTIONS
% ---------------------------------------------------------

% 1. Scan Normal Item (Not Age Restricted)
action(scan(Item),
    state(Basket, Total, none, Loyalty, StockIn, PaymentStatus),
    state([item(Item, Price, Weight) | Basket],
          NewTotal,
          none,                       % Status remains none
          Loyalty,
          StockOut,
          PaymentStatus)
) :-
    item(Item, Price, Weight, _),     % Item exists in database
    \+ age_restricted(Item),          % Item is NOT age restricted
    stock_check(Item, StockIn, StockOut),
    NewTotal is Total + Price.

% 2. Scan Age Restricted Item (Triggers Lock)
action(scan(Item),
    state(Basket, Total, none, Loyalty, StockIn, PaymentStatus),
    state([item(Item, Price, Weight) | Basket],
          NewTotal,
          age_check_needed,           % <--- SETS BLOCK
          Loyalty,
          StockOut,
          PaymentStatus)
) :-
    item(Item, Price, Weight, _),     % Item exists in database
    age_restricted(Item),             % Item requires age verification
    stock_check(Item, StockIn, StockOut),
    NewTotal is Total + Price.

% ---------------------------------------------------------
% REMOVE ACTIONS
% ---------------------------------------------------------

% 1. Remove while Blocked (The Deadlock Fix)
% If the system is waiting for age check, removing an item implies
% the user is cancelling the restricted purchase. We reset status to 'none'.
action(remove(Item),
    state(Basket, Total, age_check_needed, Loyalty, StockIn, PaymentStatus),
    state(NewBasket,
          NewTotal,
          none,                       % <--- RESETS BLOCK TO NONE
          Loyalty,
          StockOut,
          PaymentStatus)
) :-
    select(item(Item, Price, Weight), Basket, NewBasket), % Remove item
    select(stock(Item, Count), StockIn, Rest),
    NewCount is Count + 1,            % Restore stock
    StockOut = [stock(Item, NewCount) | Rest],
    NewTotal is Total - Price.

% 2. Remove Normal (Standard)
% Standard removal when the system is not blocked.
action(remove(Item),
    state(Basket, Total, none, Loyalty, StockIn, PaymentStatus),
    state(NewBasket,
          NewTotal,
          none,                       % Status remains none
          Loyalty,
          StockOut,
          PaymentStatus)
) :-
    select(item(Item, Price, Weight), Basket, NewBasket), % Remove item
    select(stock(Item, Count), StockIn, Rest),
    NewCount is Count + 1,            % Restore stock
    StockOut = [stock(Item, NewCount) | Rest],
    NewTotal is Total - Price.

%% Mohamed – Financials & Payment

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
loyalty_discount(card(CardID), SubTotal, Discount) :-
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
    Basket \= [],
    reverse(Basket, NiceOrder),  % Uses built-in reverse — works perfectly!
    nl,
    write('========= RECEIPT ========='), nl,
    print_items(NiceOrder),
    write('Total: '), write(Total), nl,
    write('Loyalty: '), write(Loyalty), nl,
    write('Payment Status: COMPLETED'), nl,
    write('==========================='), nl,
    !.

print_items([]).
print_items([item(Item, Price, _)|Rest]) :-
    write('- '), write(Item), write(' : '), write(Price), nl,
    print_items(Rest).

goal_state(state(Basket, FinalTotal, none, _, _, completed)) :-
    Basket \= [],
    FinalTotal > 0.

%% Shahd %%
% Weigh produce items
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

%% Ashraf
% Show current shopping basket
action(show_basket,
       state(Basket, Total, Blocked, Loyalty, Stock, PaymentStatus), % <--- Captured variables
       state(Basket, Total, Blocked, Loyalty, Stock, PaymentStatus)) :- % <--- Passed them through
    nl,
    write('=== CURRENT BASKET ==='), nl,
    print_items(Basket),
    write('Current Total (before tax): '), write(Total), nl,
    write('Blocked Status: '), write(Blocked), nl,
    write('======================'), nl.

%% Example Queries:    
/*Final Boss ;)
initial_state(S0), S0 = state(_,_,_,_,Stock,_) , S1 = state([], 0, none, card(card_tom), Stock, pending), action(scan(cigar_pack), S1, S2), action(verify_age(30), S2, S3), action(scan(milk), S3, S4), action(calculate_total, S4, S5), action(pay(card), S5, S6), action(print_receipt, S6, _).
*/

/* Standard Shopping
initial_state(S0), action(scan(milk), S0, S1), action(scan(chips), S1, S2), action(calculate_total, S2, S3), action(pay(cash), S3, S4), action(print_receipt, S4, _).
*/

/*Age confirmed accepted
initial_state(S0), action(scan(cigarettes), S0, S1), action(verify_age(20), S1, S2), action(calculate_total, S2, S3), action(pay(card), S3, S4), action(print_receipt, S4, _).
*/

/*Weight
initial_state(S0), action(weigh_produce(apple, 1500), S0, S1), action(scan(bread), S1, S2), action(calculate_total, S2, S3), action(pay(cash), S3, S4), action(print_receipt, S4, _).
*/

/*Show_basket
initial_state(S0), action(scan(milk), S0, S1), action(scan(bread), S1, S2), action(show_basket, S2, S3), action(scan(cigarettes), S3, S4), action(verify_age(20), S4, S5), action(calculate_total, S5, S6), action(pay(cash), S6, S7), action(print_receipt, S7, _).
*/
