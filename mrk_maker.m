function [names,onsets,durations] = mrk_maker(data, subjID, chID, chEV, fs)

% Force bit channel to be binary
dataAux = zeros(size(data));
for i = [chID chEV]
    zmark           = zscore(data(i,:));
    zmark(zmark<=0) = 0;
    zmark(zmark>0)  = 1;
    dataAux(i,:)    = zmark;
end

% Subject of interest's mask
subjmask = 2.^(0:length(chID)-1) * dataAux(chID,:);
subjmask(subjmask ~= subjID) = 0;
subjmask(subjmask == subjID) = 1;

% Remove subject mask with pulse length less than 3ms
if subjmask(1) == 1, subjmask(1) = 0; end
subjmask = marker_cleanup(subjmask, fs, 3);

% Event marker code
event    = 2.^(0:length(chEV)-1) * dataAux(chEV,:);
event    = event .* subjmask;

% fix overlapped events
event([1 end]) = 0;
de = diff(event);
i_bad = [];
n     = 0;
for i = find(de < 0)
    if event(i+1) ~= 0
        n        = n + 1;
        i_bad(n) = i+1;
    end
end
for i = find(de > 0)
    if event(i) ~= 0
        n        = n + 1;
        i_bad(n) = i;
    end
end
event(i_bad) = 0;

% remove very short events
t_min  = 1; % ms
bevent = diff(event > 0); 
ini    = find(bevent > 0); 
fin    = find(bevent < 0);
dt     = 1000 * (fin-ini) / fs;
i_bad  = find(dt < t_min);
for i = i_bad
    event(ini(i)+1:fin(i)) = 0;
end

% names, onsets and durations
N         = length(unique(event))-1;
disp(['Number of event categories found = ' num2str(N)]);
names     = cell(1,N);
onsets    = cell(1,N);
durations = cell(1,N);
for n = 1:N
    names{n}     = sprintf('event%02d', n);
    onsets{n}    = (find(diff(event == n) > 0) + 1) / fs;
    durations{n} = 0;
    disp([names{n} ' -> ' num2str(length(onsets{n}))]);
end

% debug
% figure
% ax(1) = subplot(2,1,1);
% plot((0:length(event)-1)/fs, event);
% ax(2) = subplot(2,1,2);
% hold on
% for n = 1:length(onsets)
%     plot(onsets{n}(1:end-1), diff(onsets{n}),'x-')
% end
% linkaxes(ax,'x');

end
    
function x = marker_cleanup(x, fs, t)

% minimum pulse length
n = ceil(fs*(t*10^-3));

i1 = find(diff(x) > 0) + 1;
i2 = find(diff(x) < 0);

if length(i1) ~= length(i2)
    % Error found
    disp('marker_cleanup: i1 <> i2');
    x =[];
    return
end

c = 0;
for i = 1:length(i1)
    di = i2(i)-i1(i);
    if di < 0 
        % Error found
        disp('marker_cleanup: i2-i1 < 0');
        x =[];
        return
    end
    if di <= n
        disp(['marker_cleanup: di < n at ' num2str(i1(i)/fs) 's']);
        c = c + 1;
        x(i1(i):i2(i)) = 0;
    end
end

disp(['marker_cleanup -> total=' num2str(length(i1)) ...
      ', removed=' num2str(c)]);
  
end
