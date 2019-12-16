%++++++++++++++++++++SINYAL PROJE ODEVI++++++++++++++++++++%
%__________________________________________________________%

% Butun pencerelerin kapatılması.
close all;
clear all;

%-----Notalarin parse edilmesi ve dizilere yerlestirilmesi-----%

notaMatrisi=parseMusicXML("muzik/nota.musicxml");
%Notalarin(nota.musicxml) cekilmesi ve matris halinde parse edilmesi.

frekanslar=[];%//Frekanslar Dizisi
baslangicSure=[];%//Baslangic suresinin tutulacagi dizi
devamSure=[];%//Devam suresinin tutulacagi dizi
anahtar=[];%//Frekans hesaplamak icin kullanilacak anahtarlarin tutulacagi dizi
olcu=[];%//Zarflama isleminde kullanıilacak olculerin tutulacagi dizi

%Olusturulan dizilere ilgili sutun verileri aktarilmasi.

for k=[1:120]
    anahtar=notaMatrisi(:,4);
    olcu=notaMatrisi(:,2);
    baslangicSure=notaMatrisi(:,6);
    devamSure=notaMatrisi(:,7);
    frekanslar=[frekanslar note(anahtar(k,1))];%Frekanslar, note fonksiyonu
                                               %kullanilarak hesaplanip 
                                               %diziye ekleniyor.
end

%Sutun olarak dizilerde tutulan degerlerin satir konumuna getirilmesi.%

anahtar=anahtar';
olcu=olcu';
baslangicSure=baslangicSure';
devamSure=devamSure';
frekanslar=frekanslar';

%Muzigin toplam suresini ve sinyalini tutacak dizilerin tanimlanmasi.%

zaman=[];
muzik=[];

%Harmonikler icin kullanilacak degiskenlerin olusturulması.%

harmonik=4;
harmonikler=[];%//Her bir notanın harmoniklerini tutacak dizi 
harmoniklerToplam=[];%//Harmonikleri eklenmis sinyali tutacak dizi

%Zarf icin kullanilacak degiskenlerin olusturulması.%

hangizarf=1;
    %Exponential=1
    %ADSR=2
zarflanmisMuzik=[]; 

%____________________Muzik Sinyalinin İslenmesi____________________%

for k=[1:120]%//120 Nota var. Dongu her nota icin asagidaki islemlerin 
             %//yapilmasini saglayacak.
     
    %*-*-* k. notanin zamaninin belirlenmesi *-*-*%
    %----------------------------------------------------------------%
    
      t=baslangicSure(k):1/10000:baslangicSure(k)+devamSure(k);
      t=t(1:end-1);
      
              %//Nota zamanindan bir ornek zamanin cikarilmasi.
              %//Bunun yapilmasinin nedeni arka arkaya gelen iki notanin bitis ve
              %baslangic saniyelerinin ayni olmasi. Iki sinyalin ust uste
              %gelmesini engellemek icin bir ornek zamani cikariyoruz.
             
      
     %*-*-* Muzigin toplam zamani(degisken->zaman),notalarin zamaninin(degisken->t)  
     %arka arkaya eklenerek olusturuluyor.*-*-*%
     %----------------------------------------------------------------%
     
      zaman=[zaman t];
      
     %*-*-* Zamani ve frekansi hesaplanmis notanin sinyali olusturuluyor.
     %----------------------------------------------------------------%
     
     x=cos(2*pi*frekanslar(k)*t);
     
     %*-*-* Notalarin sinyalleri(degisken ->x) arka arkaya eklenerek toplam 
     %muzik sinyali(degisken->muzik) olusuturuluyor.*-*-*%
     %----------------------------------------------------------------%
     
      muzik=[muzik x];
      
%--------------------------Harmonikler---------------------------%
%----------------------------------------------------------------%
      %*-*-* Notanin sinyalinin 'harmonikler' dizisine atilmasi.
      harmonikler=x;
      %*-*-* Harmonik sayısı 1 ise harmonik olusturulmayacak.
      %*-*-* Harmonik sayısı 1'den fazla ise sayi kadar harmonik
      %olusturulacak.
      if(harmonik~=1)
                  %*-*-* 'Harmonikler' dizisine ilk deger olan nota sinyali atildigi
                  %icin 'i' degeri 2'den baslatilmistir.  
          for i=[2 harmonik]
                  %Harmonik sinyaller hesaplanarak ust uste ekleniyor.
              harmonikler=harmonikler+(1/(i))*cos(2*pi*i*frekanslar(k)*t);  
          end
                  %*-*-* Harmonikleri ile toplanmis nota sinyallerinin arka arkaya
                  %eklenerek muzik sinyali olusturuluyor.
          harmoniklerToplam=[harmoniklerToplam harmonikler];
      end
%----------------------------------------------------------------% 

%----------------------------Zarflama----------------------------%
%----------------------------------------------------------------%

      %*-*-* Exponential zarf icin *-*-*%
      
      if(hangizarf==1)
                  
                  %Normalde zaman matrisimizde notaların tam denk geldigi
                  %saniyeleri tutuyoruz ama exponential zarf formulunde
                  %olusturdugumuz zaman uyum saglamiyor. Bu yüzden yeni bir
                  %zaman hesabı yapiyoruz.
                  

                  
          tz=0:1/10000:devamSure(k);%Olusturulan zaman 0 ile notanın devam suresi araliginda olmalı.
          tz=tz(1:end-1);%Zaman ve sinyalin denk gelmesi icin bir ornek zaman cikariliyor.
                            
                  %*-*-* Zarf formulu notalar matrisinden elde ettigimiz olculer
                  %ile hesaplanip harmonikleri eklenmis sinyalimiz ile
                  %carpiliyor.
                  
          zarf=exp(-tz/olcu(k));       
          xx=harmonikler.*zarf;
          
                  %*-*-* Zarflanan notalarin(degisken->xx) arka arkaya eklenmesi ile
                  %toplam muzik sinyali(degisken->zarflanmisMuzik) olusturuldu.
                  
          zarflanmisMuzik=[zarflanmisMuzik xx];
          
      %*-*-* ADSR zarf için *-*-*%
      
      elseif(hangizarf==2)
          
                  %*-*-*ADSR zarf icin zamanimizin boyutu hesaplanarak 4 parcaya
                  %bolunecek. Ilk parca zamanin %20'sini olusturacak.Ikinci parca
                  %zamanin %10'nu,ucuncu parca %50'sini ve dorduncu parca %20'sini
                  %olusturacak.
                  
          dur=length(t);
          zarf=[linspace(0,1.5,floor(dur/5)) linspace(1.5,1,floor(dur/10)) ones(1,floor(dur/2)) linspace(1,0,floor(dur/5))];
          
                  %*-*-* Floor fonksiyonu her zaman integer degeri elde
                  %etmemiz için kullanilmistir. Bolum kusuratli ciktiginda
                  %sayiyi alt tabana yuvarlamaktadır.
                  
                  %*-*-* 'harmonikler' sinyalimiz 'zarf' ile carpilarak
                  %'zarflanmısMuzik' dizisinin sonuna ekleniyor.
          xx=harmonikler.*zarf;
          zarflanmisMuzik=[zarflanmisMuzik xx];
      end
%----------------------------------------------------------------%
end%//Ilk for dongusunun sonu
%________________________________________________________________%


%_______________Olusturulan Sinyale Yanki Eklenmesi______________%
%________________________________________________________________%

%*-*-* Yanki olusturmak icin reverberator fonksiyonu kullanilmistir.

zarflanmisMuzik=zarflanmisMuzik';
                                 %zarflanmisMuzik degiskenin transpozesi
                                 %aliniyor cunku reverb fonksiyonu
                                 %parametre olarak sutun matris
                                 %kullaniyor.Transpozesi alinarak satirlar
                                 %sutun hucrelerine yaziliyorlar.
reverb=reverberator('PreDelay',0.2,'WetDryMix',0.5,'SampleRate',10000); 
yankiliMuzik=reverb(zarflanmisMuzik);%zarflanmisMuzik degiskenine reverb fonksiyonu uygulaniyor.

%_____Olusturulan Sinyalin Grafiginin Cizilmesi ve Calinmasi_____%
%________________________________________________________________%

plot(zaman,zarflanmisMuzik)%Ilk olarak harmonikleri eklenen ve zarflanan sinyal cizdiriliyor.
title('Yankısız Müzik')%Grafige baslik ekleniyor.
legend('Harmonik ve zarf ayarları ile oluşturulan sinyal');%Lejant ekleniyor.

figure
plot(yankiliMuzik)%Ikinci grafikte yanki eklenen sinyal cizdiriliyor.
title('Yankılı Müzik')%Grafige baslik ekleniyor.
legend('Reverb eklenen sinyal')%Lejant ekleniyor.

sound(yankiliMuzik,10000)%Yanki eklenen sinyal caldiriliyor.
