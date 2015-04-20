function prevTrack = previousTrack(track)
iter=str2num(track(3));
if(isempty(iter)), prevTrack=track; 
elseif iter==1
    prevTrack='OPT';
else
    prevTrack=track; prevTrack(3)=num2str(iter-1);
end
end