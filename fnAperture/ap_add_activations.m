function [ evDS ] = ap_add_activations( evDS, res )
%this adds in activation amounts to the event
%data structure 
%   evDS = npat.dim.ev.mat;
%   npat.dim.ev.mat = evDS;
%         inStat = load(npat.stat.file);
%         res = inStat.res;

it = res.iterations;
rS = size(it);
savCell = cell(rS(1)+1,prod(rS(2:end)));
for iCV = 1:rS(1)
    tmpCV = it(iCV,:,:,:);
    
    for iD = 1:numel(tmpCV)
        if numel(tmpCV) > 1
            [d1,d2,d3,d4] = ind2sub(size(tmpCV),iD);
%             ulbl = ['d_',num2str(d1),'_',num2str(d2),'_',num2str(d3),...
%                 '_',num2str(d4),'_'];
              ulbl = ['c',num2str(d2),'t',num2str(d3),'f',num2str(d4),'_'];
        else
            ulbl = [];
        end
        
        ap_tIndx = find(tmpCV(iD).test_idx == 1);
        if ~isfield(tmpCV(iD).perfmet{1},'corrects')
            tmpCV(iD).perfmet{1}.corrects = NaN([1 size(nanmean(tmpCV(iD).acts,3),2)]);
        end
        if ~isfield(tmpCV(iD).perfmet{1},'desireds')
            tmpCV(iD).perfmet{1}.desireds = NaN([1 size(nanmean(tmpCV(iD).acts,3),2)]);
        end
        if ~isfield(tmpCV(iD).perfmet{1},'guesses')
            tmpCV(iD).perfmet{1}.guesses = NaN([1 size(nanmean(tmpCV(iD).acts,3),2)]);
        end
        pulldata = vertcat(...
            ap_tIndx',...
            tmpCV(iD).perfmet{1}.corrects,...
            tmpCV(iD).perfmet{1}.desireds,...
            tmpCV(iD).perfmet{1}.guesses,...
            nanmean(tmpCV(iD).acts,3))';
        
        act_lbl = cell(1,size(tmpCV(iD).acts,1));
        for iiR = 1:size(tmpCV(iD).acts,1)
            act_lbl{iiR} = [ulbl,'ap_reg',num2str(iiR)];
        end
        test_act_head = {...
            [ulbl,'ap_tIndx'],...
            [ulbl,'ap_acc'],...
            [ulbl,'ap_desired'],...
            [ulbl,'ap_guess'],...
            act_lbl{:}};
        savCell{1,iD}{iCV} = test_act_head;
        savCell{iCV+1,iD} = pulldata;
    end
end

tmpHead = cell(1,size(savCell,2)); tmpAll = cell(1,size(savCell,2));
for ii = 1:size(savCell,2)
    tmpHead{ii} = savCell{1,ii}{1};
    tmpAll{ii} = vertcat(savCell{2:end,ii});
end
allcell = vertcat(horzcat(tmpHead{:}),num2cell(horzcat(tmpAll{:})));

newDS=[];
for iDS = 2:size(allcell,1)
    for iF = 1:size(allcell,2)
        newDS(iDS-1).(allcell{1,iF}) = allcell{iDS,iF}; %#ok
    end
end

%evDS = npat.dim.ev.mat;
if length(evDS) ~= length(newDS); error('datasets of different length'); end
newF = fieldnames(newDS);
for iiEv = 1:length(evDS)
    for iiF = 1:length(newF)
        evDS(iiEv).(newF{iiF}) = newDS(iiEv).(newF{iiF});
    end
end
%npat.dim.ev.mat = evDS;

%% Old code that might be nice to keep around (doesn't work on cross validation)
if 1 == 0
        test_act_info = vertcat(...
           res.iterations(1).perfmet{1}.corrects,...
           res.iterations(1).perfmet{1}.desireds,...
           res.iterations(1).perfmet{1}.guesses,...
            nanmean(res.iterations(1).acts,3));

        act_lbl = cell(1,size(res.iterations(1).acts,1));
        for iiR = 1:size(res.iterations(1).acts,1)
            act_lbl{iiR} = ['ap_reg',num2str(iiR)];
        end

        test_act_head = {'ap_acc','ap_desired','ap_guess',act_lbl{:}};

        %evDS = npat.dim.ev.mat;
        for iiEv = 1:length(evDS)
            for iiF = 1:length(test_act_head)
                evDS(iiEv).(test_act_head{iiF}) = test_act_info(iiF,iiEv);
            end
        end
        %npat.dim.ev.mat = evDS;
end

end
