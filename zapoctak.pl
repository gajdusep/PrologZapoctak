% Program for solving nonogram puzzle
%
% I took some inspiration in this solution:
%    https://gist.github.com/klemens/b61f141ade46da56fc7d
%    (test are took from there).
% Test copied also from here:
%    https://github.com/heyLu/nonogram-prolog/blob/master/nonogram.pl
% Rewriten from here:
%    https://www.nonograms.org/nonograms/i/14357


% -------------------------------------
% Algorithm is based on brute force and probability of certain row.
% E.g: If there are only 3 possibilities for certain row, it is
% better to try them before the possibilities of another row with 7 posibilities.

%    E.g.: row parameters are [[1],[5],[2,2]] and the length of row is 5.
%    The first row has 5 possibilities, the second 1, the third also 1.
%    Therefore the second and the third will be tested the first.

% ----  Implementation: -------
% In the preparing part, we will make a lists of all possibilities for every row.
%
% Then we will make a list of data structs.
% data struct contains information about certain row:
%    data(NumberOfPosibilities,OriginalRowNumber,ListOfAllPosibilities).
%
% Then we will sort the list of data structs according to the number
% of possibilities.
%
% Then we will go through the list and try to add the rows into the
% final matrix. After adding each row to the result matrix, we
% will check if the result is right. If yes, we call recursively the
% another row. If not, we must try another possibility in the list of
% possibilities.


magic(Rows, Cols,Matrix) :-
    length(Rows, NoRows),
    length(Cols, NoCols),
    generateSorted(Rows,NoCols,SortedRows),
    genEmptyMatrix(NoRows,NoCols,Matrix),
    nonog(SortedRows,Cols,NoRows,Matrix).



% ---------------------------------------
% -- functions for working with matrix --
% ---------------------------------------

% generates empty matrix of free vars
% test: genEmptyMatrix(4,3,R).
genEmptyMatrix(NoRows,NoCols,Matrix) :-
    length(HalfRes,NoRows),
    genCols(NoCols,HalfRes,Matrix).
genCols(NoCols,[_|HalfRes],[Line|Rest]) :-
    length(Line,NoCols),
    genCols(NoCols,HalfRes,Rest).
genCols(_,[],[]).

% test: genEmptyMatrix(4,3,R), row(1,R,K).
% test for changing:
%   genEmptyMatrix(4,3,R), row(1,R,[a,b,c]), col(1,R,[x,b,c,d]). false
%   genEmptyMatrix(4,3,R), row(1,R,[a,b,c]), col(1,R,[a,b,c,d]). OK
row(N, Matrix, Row) :-
    nth1(N, Matrix, Row).
col(N, Matrix, Col) :-
    maplist(nth1(N), Matrix, Col).



% -----------------------------
% -- part for preparing data --
% -----------------------------

% generates sorted set of all possible solutions for all lines
% and sorts it according to number of possibilities for each line
% test: generateSorted([[2,1],[1,1],[3]],5,R).
generateSorted(Rows,Length,Result) :-
    generateStructRows(Rows,Length,DataSet,1),
    sort(DataSet,Result).

% test: generateStructRows([[2,1],[1,1],[3]],5,R,1).
generateStructRows([H|TRows], Length, [R|DataSet],OrigNo) :-
    generateStruct(H,Length,OrigNo,R),
    O1 is OrigNo + 1,
    generateStructRows(TRows,Length,DataSet,O1).
generateStructRows([],_,[],_).

% generates set of all possible solutions for one line
% and puts it to the data struct.
generateStruct(Params,Length,OrigNo,data(L,OrigNo,Result)) :-
    generateList(Params,Length,Result),
    length(Result,L).


% test: generateList([2,1],5,R).
generateList(Params,Length, Result) :-
    findall(Line,generateLine(Line,Params,Length),Result).



% ----------------------------------------------
% -- generating lines according to parameters --
% ----------------------------------------------

% line -> called line, because it doesn't matter if it is column or row
% This function can generate lines, but it is used also for checking if
% the row/column is in the right shape...
%
% generateLine(Line, Parameters, Length)
%
% testing: generateLine(L,[1,2],6).
% testing: generateLine(['.','+','.','+'],[1,1],4). -> true
generateLine([],[],0).
generateLine(['.'|T],Params,Length) :- Length > 0, L is Length - 1, generateLine(T,Params,L).
generateLine(['+'|T],[P|Params],Length) :-
    P1 is P - 1,
    L is Length - 1,
    mustGenerate(T,P1,L,RemainLength,RemainList),
    generateLine(RemainList,Params, RemainLength).

% helping function for generating
% +List, +PlusesRemaing, +Length, +RemainLength, -RemainingList
mustGenerate(['.'|LineT],0,L,L1,LineT) :- L1 is L - 1.
mustGenerate([],0,0,0,[]).
mustGenerate(['+'|LineT],PlRemain,L,ResultL,ResultList) :-
    PlRemain > 0,
    L1 is L - 1,
    Pl1 is PlRemain - 1,
    mustGenerate(LineT, Pl1, L1, ResultL, ResultList).



% ------------------
% -- solving part --
% ------------------

nonog([data(_,OrigRowsNo,[HPos|TPos])|SRows],Cols,ColLen,Matrix) :-
    % either the first possibility of actual row goes well
    % and we can call recursively on another row
    (row(OrigRowsNo,Matrix,HPos),
    checkCols(Matrix,Cols,1,ColLen),
    nonog(SRows,Cols,ColLen,Matrix));
    % or we have to take the second (and further...) possibility of certain row
    nonog([data(_,OrigRowsNo,TPos)|SRows],Cols,ColLen,Matrix).
nonog([],_,_,_).


% checkCols checks if all the columns are right according to columns
% parameters. It contains copy_term function because if we didn't copy
% the column, it would be changed also in the Matrix (we only want to
% check it, not change it)
%
% test:
% genEmptyMatrix(4,3,R),row(1,R,['+','.','+']),checkCols(R,[[2],[1,1],[2]],1,4).
checkCols(Matrix,[HCols|TCols],ActNo,Length) :-
    col(ActNo,Matrix,Col),
    copy_term(Col,Coll),
    generateLine(Coll,HCols,Length),
    !,
    No1 is ActNo + 1,
    checkCols(Matrix,TCols,No1,Length).
checkCols(_,[],_,_).



% ------------------
% -- testing part --
% ------------------

test0 :-
    Rows = [[2],[1]],
    Cols = [[1],[1],[1]],
    test(Rows,Cols).

test1 :-
    Rows = [[3],[4,2],[6,6],[6,2,1],[1,4,2,1],[6,3,2],[6,7],[6,8],[1,10],
                [1,10],[1,10],[1,1,4,4],[3,4,4],[4,4],[4,4]],
    Cols = [[1],[11],[3,3,1],[7,2],[7],[15],[1,5,7],[2,8],[14],[9],[1,6],
                [1,9],[1,9],[1,10],[12]],
    test(Rows,Cols).

test2 :-
    Rows = [[3],[2,1],[3,2],[2,2],[6],[1,5],[6],[1],[2]],
    Cols = [[1,2],[3,1],[1,5],[7,1],[5],[3],[4],[3]],
    test(Rows,Cols).

test3 :-
    Rows = [[9],[7,2],[2,5,2],[2,2,2,2],[1,3,3,1],[1,1],[1,2,2,1],[1,2,2,1],[1,1],[1,1,1],[1,2,1],[2,1,2,2],[2,5,2],[2,2],[9]],
    Cols = [[9],[2,2],[2,2],[2,2],[5,2,1,1],[5,2,1,1],[3,1,1,1,1],[3,1,1],[5,2,1,1],[1,2,2,3,1],[1,1,2,1],[2,2],[2,2],[2,2],[9]],
    test(Rows,Cols).

test4 :-
    Rows = [[4],[1],[3,1],[2],[2]],
    Cols = [[1,1],[1,1],[3],[1,2],[3]],
    test(Rows,Cols).

test5 :-
    Rows = [[5,3,2],[3,5,1],[7,1,1],[1,7,1],[3,3,2],[2,1,7],[1,1,4,1],[1,2,2,3],[3,5],[2,3],[3],[4],[4],[3,1],[2,4]],
    Cols = [[7,1],[3,2,2],[5,3],[1,2,1,5],[4,6,1],[4,10],[3,1],[2,2],[6],[1,4],[4],[2,2],[5],[1,2,3],[9]],
    test(Rows,Cols).

test6 :-
    Rows = [[4],[1,1,1],[5,4],[1,1,1,1],[12],[11],[8],[4,1,1],[1,1,1,2],[1,1,1]],
    Cols = [[4],[1,2,2],[4,1],[1,6],[7],[3],[3],[3],[3,6],[1,1,3],[1,1,5],[1,4,2]],
    test(Rows,Cols).

test7 :-
    Rows = [[7],[2,4],[2,3],[4,4],[5,4],[5,4],[5,4],[3,4],[4],[3],[3],[2],[1],[1],[],[3],[5],[5],[5],[3]],
    Cols = [[4],[6],[7],[2,5,3],[1,3,5],[1,3,5],[1,2,5],[2,3,3],[11],[10],[8],[5]],
    test(Rows,Cols).

% no result test
test8 :-
    Rows = [[1],[2]],
    Cols = [[2],[2]],
    test(Rows,Cols).


% prints time spent on execution of algorithm
test(Rows,Cols) :-
    time(magic(Rows,Cols,M)),
    printRes(M).


% pretty printing part
printRes([]).
printRes([H|T]) :-
    printLine(H),
    printRes(T).

printLine([]) :-
    writeln(' ').
printLine(['+'|T]) :-
    write(■),
    printLine(T).
printLine(['.'|T]) :-
    write(☐),
    printLine(T).
