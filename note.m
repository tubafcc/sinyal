function frekans=note(deger)
    %*-*-* Gelen değer 0 ise frekans formülünden hesaplanmadan sıfır atanması.
    %Frekansı 0 olan yerlerde müziğin beklemesi gerektiği için dikkate alınmalıdır.
    if(deger==0) 
      frekans=0;          
    else
      frekans=(2^((deger-69)/12))*440;
    end
end