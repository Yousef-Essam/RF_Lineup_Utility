function IIP3_total = IIP3_cascade(IIP3, Gain)
    fact = 0;
    Gain = [1 Gain];
    for i = 1:length(IIP3)
        fact = fact + prod(Gain(1:i))^2 / IIP3(i)^2;
    end
    
    IIP3_total = sqrt(1/fact);
end