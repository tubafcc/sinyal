# Sinyal İşleme Projesi

Tuğba FIÇICI

30116005

Sinyal İşleme

Proje: MATLAB ile sentezleme

## MuseScore ile yazılmış notalar

![](muzik/nota-1.png)

## Parse Edilmiş Veri Hakkında

###### Parse edilmiş veri içerisinde kullanacağımız sütunlar:

- 4.Sütun: Notaların MIDI numaraları

- 6.Sütun: Notanın başlangıç saniyesi

- 7.Sütun: Devam ettiği süre

4.Sütun ile notaların frekanslarını

>freakans = 2^((m-69)/12)*440 

formülü ile hesaplayacağız. Burada "m" ile gösterilen yere 4.sutündan aldığımız değerleri kullanacağız. 6 ve 7. sütunlar bir notanın ne zaman başlayacağı ve ne zaman biteceğini hesaplamamızı sağlayacak. Elde ettiğimiz zamanları arka arkaya ekleyerek sinyalimizin t zamanını oluşturmuş olacağız.

Aşağıdaki formül ile notaların sinyallerini oluşturacak ve arka arkaya ekleyerek x sinyalimizi oluşturacağız.

>Nota Sinyali=Genlik x cos(2 x pi x freakans x zaman)


