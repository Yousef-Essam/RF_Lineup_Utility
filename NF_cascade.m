function NF_total = NF_cascade(NF, Gain)
    NF_total = 1;
    Gain = [1 Gain];
    for i = 1:length(NF)
        NF_total = NF_total + (NF(i) - 1) / prod(Gain(1:i));
    end
end