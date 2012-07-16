%% Beyasian Texas Hold'Em
%% CS8803 PGM
%% Fall 2011
%% David Tsai (caihsiaoster@gatech.edu)
%%
%% Please read write-up and readme.txt before you start coding!
%%
%% INSTRUCTIONS:
%% Hand Model : Fill in the missing code in StageUpdater.m
%% Betting Strategy : Fill in the missing code in MakeDecision.m
%% Opponent Modeling : Fill in the missing code in UpdateOpponent.m


function poker_main()

    clear all;
    global history
    
    N = 8;  % number of players
    GAME_NUM = 5;  % number of games - 25
    pos = 0;
    RAISE_LIMIT = 3;  % maximum number of raises each round
    SBU = 10;
    SB = SBU / 2;
    BB = SBU;
    COIN = 5000;  % money each player initially has
    money = ones(1,N) * COIN;  % money each player currently has
    oppo_model = cell(N,1);  % opponent model parameters

    CALL = 1;  %% CALL or CHECK
    RAISE = 2; %% BET or RAISE
    FOLD = 3;  %% FOLD

    % Init global variables
    MakeGlobals();
    
    % Lists of function handles to support calling different agents
    % Currently just for MakeDecision, but will create for all agent
    % functions before tournament
    MakeDecisionHandles = cell(1,N);
    for i=1:N
         MakeDecisionHandles{i} = @MakeDecision_AlwaysBet;
    end
    
    history = struct('showdown',[],'board',[],'hole',[],'money',[],'bet',[],'pos',[],'start',[],'stage_starts',[],'row_index',1);
    %ARVIND: Adding redundant historyA variable
    history_pre = history;
    historyA = history;
    
    % Control whether game record goes to a file or the screen
    % fid = fopen('record.txt','w');
    fid = 1;
    fprintf(fid, 'Game started!\n');

    % main loop
    for round = 1:GAME_NUM
        disp(round);
        str = '*************** Game ';
        str = [str, num2str(round)];
        str = [str, ' ******************'];
        fprintf(fid, '\n\n%s\n', str);
        
        % Pause between games or some number of games
        fprintf(1, 'Waiting for a key press\n');
        % if mod(round,10) == 0
        %    pause; % Wait for user every 10 games
        % end
        pause;
        
        % initialization
        pos = mod(pos+1,N);
        first_pos = pos + 1;
        second_pos = first_pos + 1;
        if (second_pos > N)
            second_pos = 1;
        end
        pot = 0;
        hole_card = zeros(N,2);
        board_card = ones(1,5)*-1;
        all_cards = randperm(52) - 1;  % see readme for card representation
        cur = 1;  % current card pointer when dealing cards
        active = ones(1,N); % binary vector indicating if a player is
                            % still alive or already folded
                            
        history.pos = [history.pos; first_pos];  % Record first player to bet for this round
        history.stage_starts = zeros(1,4);  % Record of start of betting (betting matrix row index) for each stage
		% ARVIND: Adding redundant historyA variable to contain the same contents as history
		historyA = history;

        %--------------------  Pre-Flop Stage -------------------------
        
        stage = 0;        
        % deal hole cards
        for i = 1:N
            hole_card(i,1) = all_cards(cur);
            cur = cur + 1;
            hole_card(i,2) = all_cards(cur);
            cur = cur + 1;
        end

        % bet
        start = true;
        cur_pos = first_pos;
        cur_pot = 0; % pot in this round
        raise_num = 0; % num of raises in this round
        paid = zeros(1,N); % money each player already paid in this round
        end_pos = -1;
        tmp_bet = zeros(1,N);
        stage_bet = [];  % Record to hold all betting activity for current stage
        fprintf(fid, '\nBeginning: \n\t');
        PrintGameInfo(fid,active,money,pot,-1,stage,history,hole_card);
        
        su_info = []; % stage_updater info
        % initiate the structure passing to player
        % ARVIND: Adding redundant historyA variable into info structure
        info = struct('stage',0,'pot',pot,'cur_pos',cur_pos,'cur_pot',cur_pot,'first_pos',first_pos,'board_card',board_card,'hole_card',zeros(1,2),'active',active,'paid',paid,'history',history_pre,'su_info',su_info,'oppo',[],'historyA',historyA);
        
        while (cur_pos~=end_pos)
            if (active(cur_pos) == true)
                if (cur_pos == first_pos && start == true)
                    % must bet small blind
                    pot = pot + SB;
                    money(cur_pos) = money(cur_pos) - SB;
                    paid(cur_pos) = SB;
                    fprintf(fid, '\nPlayer %d paid the small blind\n\n', cur_pos);
                    decision = RAISE; % JIM2 added
                    % Add bet to history record
                    tmp_bet(cur_pos) = decision;
                else
                    info.pot = pot;
                    info.cur_pos = cur_pos;                    
                    info.cur_pot = cur_pot;
                    info.hole_card = hole_card(cur_pos,:);
                    info.active = active;
                    info.paid = paid;
		    info.oppo = oppo_model(cur_pos);
                    
                    %% TODO : fill in the following function
                    su_info = StageUpdater(info);
 
                    info.su_info = su_info;                    
                    
                    if (cur_pos == second_pos && start == true)
                        % Must bet the big blind
                        fprintf(fid, '\nPlayer %d paid the big blind\n\n', cur_pos);
                        decision = RAISE;
                        start = false;
                    else
                        %% TODO : fill in the following function
                        % decision = MakeDecision(info);
                        decision = MakeDecisionHandles{cur_pos}(info);                    
                        if (decision == RAISE && raise_num == RAISE_LIMIT)
                            decision = CALL;
                        end
                    end
                    
                    % Add bet to history record
                    tmp_bet(cur_pos) = decision;

                    if (decision == CALL)  % call
                        pay = cur_pot - paid(cur_pos);
                        pot = pot + pay;
                        money(cur_pos) = money(cur_pos) - pay;
                        paid(cur_pos) = paid(cur_pos) + pay;
                    elseif (decision == RAISE)  % raise
                        raise_num = raise_num + 1;
                        end_pos = cur_pos;
                        pay = cur_pot - paid(cur_pos) + SBU;
                        pot = pot + pay;
                        money(cur_pos) = money(cur_pos) - pay;
                        paid(cur_pos) = paid(cur_pos) + pay;
                        cur_pot = cur_pot + SBU;
                    else  % fold
                        active(cur_pos) = false;
                    end
                end
            end

            % Check for case of everyone folding but one
            if (sum(active) == 1)
                break;
            end

            cur_pos = cur_pos + 1;
            if (cur_pos > N)
                % Every time you wrap-around, start a new row in betting
                % matrix to preserve re-raise history
                stage_bet = [stage_bet; tmp_bet];
                tmp_bet = zeros(1,N);
                cur_pos = 1;
            end
        end
        
        % Update betting history for preflop
        if sum(tmp_bet) > 0
            stage_bet = [stage_bet; tmp_bet];
            tmp_bet = zeros(1,N);
        end
        history.stage_starts(stage+1) = history.row_index;
        history.bet = [history.bet; stage_bet];
        history.row_index = history.row_index+size(stage_bet,1);
        %ARVIND: Adding this line so as to add history variable into info structure via historyA parameter
        info.historyA = history;
		% ARVIND: Adding redundant historyA variable to contain the same contents as history
		historyA = history;
        
        fprintf(fid, '\nAfter PRE-FLOP: \n\t');
        PrintGameInfo(fid,active,money,pot,0,stage,history,hole_card);
        
        if (sum(active) > 1)

            %--------------------  Post Flop Stage -------------------------

            for stage = 1:3
                % deal board cards
                if (stage == 1)  %% flop
                    for i = 1:3
                        board_card(i) = all_cards(cur);
                        cur = cur + 1;
                    end
                else
                    board_card(stage+2) = all_cards(cur);
                    cur = cur + 1;
                end

                % bet
                cur_pot = 0;
                raise_num = 0;
                paid = zeros(1,N);
                end_pos = -1;
                cur_pos = first_pos;
                start = true;
                tmp_bet = zeros(1,N);
                stage_bet = [];  % Record to hold all betting activity for current stage

                %ARVIND: Adding redundant historyA variable into info structure
                info = struct('stage',stage,'pot',pot,'cur_pos',cur_pos,'cur_pot',cur_pot,'first_pos',first_pos,'board_card',board_card,'hole_card',zeros(1,2),'active',active,'paid',paid,'history',history_pre,'su_info',su_info,'oppo',[],'historyA',historyA);

                while (cur_pos~=end_pos)
                    if (active(cur_pos) == true)
                        if (start == true)
                            end_pos = cur_pos; 
                            start = false;
                        end

                        info.pot = pot;
                        info.cur_pos = cur_pos;
                        info.cur_pot = cur_pot;                    
                        info.hole_card = hole_card(cur_pos,:);
                        info.active = active; 
                        info.paid = paid;
		        info.oppo = (oppo_model(cur_pos));

                        %% TODO : fill in the following function
                        su_info = StageUpdater(info);

                        info.su_info = su_info;
                        
                        %% TODO : fill in the following function
                        decision = MakeDecisionHandles{cur_pos}(info);
                        % decision = MakeDecision(info); 

                        if (decision == RAISE && raise_num > RAISE_LIMIT)
                            decision = CALL;
                        end

                        % Add bet to history record
                        tmp_bet(cur_pos) = decision;

                        if (decision == CALL)  % call or check
                            pay = cur_pot - paid(cur_pos);
                            pot = pot + pay;
                            money(cur_pos) = money(cur_pos) - pay;
                            paid(cur_pos) = paid(cur_pos) + pay;
                        elseif (decision == RAISE)  % raise or bet
                            raise_num = raise_num + 1;
                            end_pos = cur_pos;
                            pay = cur_pot - paid(cur_pos) + SBU;
                            pot = pot + pay;
                            money(cur_pos) = money(cur_pos) - pay;
                            paid(cur_pos) = paid(cur_pos) + pay;
                            cur_pot = cur_pot + SBU;
                        else  % fold
                            active(cur_pos) = false;
                        end
                    end

                    % Check for case of everyone folding but one
                    if (sum(active) == 1)
                        break;
                    end 

                    cur_pos = cur_pos + 1;
                    if (cur_pos > N)
                        % Every time you wrap-around, start a new row in betting
                        % matrix to preserve re-raise history
                        stage_bet = [stage_bet; tmp_bet];
                        tmp_bet = zeros(1,N);
                        cur_pos = 1;
                    end

                end

                % Update betting history for postflop stages
                if sum(tmp_bet) > 0
                    stage_bet = [stage_bet; tmp_bet];
                    tmp_bet = zeros(1,N);
                end
                history.stage_starts(stage+1) = history.row_index;
                history.bet = [history.bet; stage_bet];
                history.row_index = history.row_index+size(stage_bet,1);
                %ARVIND: Adding this line so as to add history variable into info structure via historyA parameter
                info.historyA = history;
				% ARVIND: Adding redundant historyA variable to contain the same contents as history
				historyA = history;

                if (stage == 1)
                    fprintf(fid, '\nAfter FLOP: \n\t');
                elseif (stage == 2)
                    fprintf(fid, '\nAfter TURN: \n\t');
                else
                    fprintf(fid, '\nAfter RIVER: \n\t');
                end
                PrintGameInfo(fid,active,money,pot,0,stage,history,hole_card,board_card);

                if (sum(active) == 1)
                    disp('Game ends!');
                    break;
                end

            end
        
        end
        
        % Game is over, do final processing
        if (sum(active) == 1)
            % Everyone folded except one
            winner = find(active, 1);
            money(winner) = money(winner) + pot;
            final_active = active * 0;
            showdown = false;
        else
            % Showdown
            final_active = active;
            showdown = true;
            winner = compare_showdown(active,hole_card,board_card);
            % Divide pot equally between all winners in case of tie
            money(winner) = money(winner) + pot/size(winner,2);
        end
        
        % Ensure that there is at least one row of bets in table for each
        % stage, which is set to zero if the stage never happened
        for j=0:(2-stage)
            stage = stage + 1;
            history.stage_starts(stage+1) = history.row_index;
            tmp_bet = zeros(1,N);
            history.bet = [history.bet; tmp_bet];
            history.row_index = history.row_index + 1;
        end
                
        % Finalize history of round that ended
        history.start = [history.start; history.stage_starts];
        history.showdown = [history.showdown;showdown];
        history.board = [history.board; board_card];
        % Hole cards visible at showdown
        hole_tmp = hole_card;
        for i=1:N
            if ~final_active(i)
                % Hide hole cards of players who didn't go to showdown
                hole_tmp(i,:) = [-1 -1];
            end
        end
        history.hole = [history.hole; reshape(hole_tmp',1,2*N)];
        history.money = [history.money; money];
        history_pre = history;
        %ARVIND: Adding redundant historyA variable
        historyA = history;
        
        for i = 1:N
            %% TODO : fill in the following function
            oppo = UpdateOpponent(history, i);
            oppo_model(i) = mat2cell(oppo,size(oppo,1),size(oppo,2));
        end
        
        str = ['Player ', num2str(winner), ' WINS!!!'];
        fprintf(fid, '\n%s\n\t', str);
        PrintGameInfo(fid,active,money,pot,1,stage,history,hole_card,board_card);
        % PrintGameInfo(1,board_card,active,money,pot);
        
    end
    
    fprintf(fid, '\nMatch Over!!!!\n\n');
    
    % Report Match Results
    Pstat = cell(1,N);
    for i=1:N
        % Compute player betting statistics
        actind = find(history.bet(:,i) > 0);
        act = history.bet(actind,i)';
        actlen = size(act,2);
        for j=1:3
            actv(j) = size(find(act == j),2)/actlen;
        end
        Pstat{i} = actv;
    end
    [Mrank, ind] = sort(money, 'descend');
    fprintf(fid, 'Rank:\t');
    fprintf(fid, '%d\t\t\t\t', ind);
    fprintf(fid, '\n');
    fprintf(fid, 'Earn:\t');
    fprintf(fid, '%d\t\t\t', Mrank);
    fprintf(fid, '\n');
    fprintf(fid, 'Action:\t');
    fprintf(fid, '%.2f/%.2f/%.2f\t', Pstat{:});
    fprintf(fid, '\n');
    
    % fclose(fid);
    
end

% Determine winner in showdown by comparing hand categories and high cards
% In the case of tie hands, this returns a list of winners
%
function winner = compare_showdown(active, hole_card, board_card)
    final_card = [];
    for i = 1:size(active,2)        
        final_card = [final_card;[board_card hole_card(i,:)]];
    end  
    
    max_type = -1;
    max_card = -1;
    for i = 1:size(final_card,1)
        if (active(i) == true)
            card = final_card(i,:);
            [type highcard] = final_type(card);
            if (type > max_type)
                % New winner on hand type
                winner = i;
                max_type = type;
                max_card = highcard;
            elseif (type == max_type)
                % JIM modified
                if (type == 1 || type == 2 || type == 6)
                    % When comparing two hands that are both one pair, two
                    % pairs, or full house, look at both high cards
                    if highcard(1) > max_card(1)
                        % New winner on high card
                        winner = i;
                        max_card = highcard;
                    elseif highcard(1) == max_card(1)
                        if highcard(2) > max_card(2)
                            % New winner on high card
                            winner = i;
                            max_card = highcard;
                        elseif highcard(2) == max_card(2)
                            % Tie hand
                            winner = [winner i];
                        end
                    end
                else
                    % All other tie hands are determined by single high
                    % card
                    if (highcard > max_card)
                        % New winner on high card
                        winner = i;
                        max_card = highcard;
                    elseif highcard == max_card
                        % Tie hand
                        winner = [winner i];
                    end
                end
            end
            
        end
    end
end

% Initialize global variables. Includes:
%   - Create a cell array of card names according to the card index coding
%       Used to pretty print hand info
%   - Tables of prior and conditional probabilities for final hands
function MakeGlobals()
    global CARDnames VALnames SUITnames FHnames Knames SFnames FHprior FHcdf SFpred Kpred
    N = ['2'; '3'; '4'; '5'; '6'; '7'; '8'; '9'; 'T'; 'J'; 'Q'; 'K'; 'A'];
    S = ['D'; 'C'; 'H'; 'S'];
    % Construct outer product of number-suit
    X = repmat(N(:).', [length(S) 1]);
    Y = repmat(S(:), [1 length(N)]);
    VALnames = N;
    SUITnames = S;
    CARDnames = cellstr([X(:) Y(:)]);
    
    % Cell arrays of strings for pretty printing hands and categories
    FHnames = {'Junk' 'K2' 'K2K2' 'K3' 'S' 'F' 'K3K2' 'K4' 'SF'};
    Knames = {'NP' 'K2' 'K2K2' 'K3' 'K3K2' 'K4'};
    SFnames = {'J' 'SF' 'SFO4' 'SFO3' 'SFI4' 'F' 'F4' 'F3' 'S' 'SO4' 'SO3' 'SI4' 'SFO3-F4' 'SFO3-SI4' 'SFO3-SO4' 'SI4-F3' 'SI4-F4' 'SO3-F3' 'SO3-F4' 'SO4-F3' 'SO4-F4'};
    
    % Final Hand probabilities
    % Probability of making each final hand with 7 cards, default model
    % for predicting opponent's hand
    FHprior = [0.1728 0.438 0.2352 0.0483 0.048 0.0299 0.0255 0.0019 0.0004];
    FHcdf = fliplr(cumsum(fliplr(FHprior)));
    % SFpred(SG,SF_c,SF_f) = P(SF_f | SF_c, SG) for SG=1,2 (ie post-flop post-turn)
    % Note: To examine the CPT use reshape(SFpred(i,:,:), 21, 3) for i=1,2
    SFpred(1,:,:) = reshape([0.0 0.0 0.0, 1.0 0.0 0.0, 0.0842 0.2784 0.2414, 0.0028 0.0389 0.0416, 0.0426 0.3145 0.1249, 0.0 1.0 0.0, 0.0 0.3497 0.0, 0.0 0.0416 0.0, 0.0 0.0 1.0, 0.0 0.0 0.3145, 0.0 0.0 0.0444, 0.0 0.0 0.1647, 0.0028 0.3469 0.0416, 0.0028 0.0389 0.1360, 0.0028 0.0389 0.2784, 0.0 0.0416 0.1647, 0.0 0.3497 0.1249, 0.0 0.0416 0.0416, 0.0 0.3497 0.0250, 0.0 0.0416 0.2756, 0.0 0.3497 0.2414], 3, 21)';
    SFpred(2,:,:) = zeros(21,3);
    SF5 = 2; SFO4 = 3; SFI4 = 5; F5 = 6; F4 = 7; S5 = 9; SO4 = 10; SI4 = 12;
    SFpred(2,SF5,:) = [1.0 0.0 0.0];
    SFpred(2,SFO4,:) = [0.0435 0.1522 0.1739];
    SFpred(2,SFI4,:) = [0.0217 0.1739 0.0870];
    SFpred(2,F5,:) = [0.0 1.0 0.0];
    SFpred(2,F4,:) = [0.0 0.1957 0.0];
    SFpred(2,S5,:) = [0.0 0.0 1.0];
    SFpred(2,SO4,:) = [0.0 0.0 0.1739];
    SFpred(2,SI4,:) = [0.0 0.0 0.0870];
    % Kpred(SG, K_c, K_f) = P(K_f | K_c, SG) for SG=1,2 (ie post-flop post-turn)
    % Note: To examine the CPT use reshape(Kpred(i,:,:), 17, 3) for i=1,2
    Kpred(1,:,:) = reshape([0.0 0.0 0.0139 0.0832 0.4440 0.4589, 0.0009 0.0250 0.0666 0.3000 0.6075 0.0, 0.0019 0.1619 0.0 0.8362 0.0 0.0, 0.0426 0.1249 0.8326 0.0 0.0 0.0, 0.0435 0.9565 0.0 0.0 0.0 0.0, 1.0 0.0 0.0 0.0 0.0 0.0], 6, 6)';
    Kpred(2,:,:) = reshape([0.0 0.0 0.0 0.0 0.3910 0.609, 0.0 0.0 0.0435 0.2609 0.6956 0.0, 0.0000 0.0870 0.0 0.9130 0.0 0.0, 0.0217 0.196 0.7823 0.0 0.0 0.0, 0.0217 0.9783 0.0 0.0 0.0 0.0, 1.0 0.0 0.0 0.0 0.0 0.0], 6, 6)';
end

% Create a list of post-flop hand category strings in a cell array, 
% one for each player. Each string is a combination of the K and SF 
% categories with their high cards, separated by a '|' 
% (e.g. K2-A|F3-T). A '*' is used for inactive players
function handCat = ListHandCategories(active, hole_card, board_card)
    handCat = cell(2, size(active,2));
    for i = 1:size(active,2)
        if active(i)
            [Kcat SFcat] = hand_category(hole_card(i,:), board_card);
            handCat{1,i} = Kcat;
            handCat{2,i} = SFcat;
        else
            handCat{1,i} = '     **** ';
            handCat{2,i} = '     **** ';
        end
    end
end

% Given hole cards and board cards for a single hand, generate string
% containing name of final hand category, including high cards
function Fcat = FinalCategory(hole_card, board_card)
    global VALnames FHnames
    v = [hole_card board_card];
    [type highcard] = final_type(v);
    highnames = VALnames(highcard-1);     % -1 comes from fact that val is in range 2-14
    Fcat = sprintf('%5s-%2s', FHnames{type+1}, highnames);
end

% Create a list of final hand strings in a cell array, one for each player.
% A '*' is used for inactive players
function Fhands = ListFinalHands(active, hole_card, board_card)
    handCat = cell(1, size(active,2));
    for i = 1:size(active,2)
        if active(i)
            Fhands{i} = FinalCategory(hole_card(i,:), board_card);
        else
            Fhands{i} = '   **** ';
        end
    end
end

% Function to pretty print game state after each stage
% game_status
%    -1 : Game hasn't started
%     0 : Game in play
%     1 : Game over
function PrintGameInfo(fid, active, money, pot, game_status, stage, history, hole_card, board_card)
    global CARDnames
    if (nargin == 9)
        bcvalid = board_card(find(board_card ~= -1));
        bcnames = CARDnames(bcvalid+1);   % +1 because card indices range from 0 to 51
        fprintf(fid, 'Board cards:\t');
        fprintf(fid, '%s\t', bcnames{:});
        fprintf(fid, '\n\t');
    end
    
    HClist = reshape(hole_card', numel(hole_card), 1);
    HCnames = CARDnames(HClist+1);   % +1 because card indices range from 0 to 51
    fprintf(fid, 'Hole cards:\t');
    fprintf(fid, '     %s-%s\t', HCnames{:});
    fprintf(fid, '\n\t');
 
    if (nargin == 9)
        if game_status == 1
            % At end of game, show final hand categories
            Ftypes = ListFinalHands(active, hole_card, board_card);
            fprintf(fid, 'Final hands:\t');
            fprintf(fid, '%s\t', Ftypes{:});
            fprintf(fid, '\n\t');
        else
            % At an intermediate stage, show all hand categories
            Htypes = ListHandCategories(active, hole_card, board_card);
            fprintf(fid, 'K types:\t');
            fprintf(fid, '%s\t', Htypes{1,:});
            fprintf(fid, '\n\t');

            fprintf(fid, 'SF types:\t');
            fprintf(fid, '%s\t', Htypes{2,:});
            fprintf(fid, '\n\t');
        end
    end
    
    fprintf(fid, 'Player status:\t'); 
    fprintf(fid, '%d\t', active);
    fprintf(fid, '\n\t');
    
    if game_status == 0
        % Print betting history
        row_start = history.stage_starts(stage+1);
        row_end = history.row_index-1;
        for i=row_start:row_end
            % Print each row
            if (i == row_start)
                fprintf(fid, 'Bets:\t');
            else
                fprintf(fid, '\t\t\t');
            end
            fprintf(fid, '%d ', history.bet(i,:));
            fprintf(fid, '\n');
        end
        fprintf(fid, '\t');
    end
    
    fprintf(fid, 'Money left:\t'); 
    fprintf(fid, '%d\t%d\t', money);
    fprintf(fid, '\n');
    
    fprintf(fid, '\tPot:\t'); 
    fprintf(fid, '%d\n', pot);
end
    

