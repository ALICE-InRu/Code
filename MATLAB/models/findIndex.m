function active = findIndex(allFeatures, activeFeatures)
active=[];
for feat = 1:length(allFeatures)
    if(~isempty(intersect(allFeatures{feat},activeFeatures)))
        active=[active feat];
    end
end
end