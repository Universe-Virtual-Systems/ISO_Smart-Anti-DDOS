key agent;

key last_agent;
list last_agents;

integer touch_counter;
list touch_counters;

integer touch_block;
list touch_blocks;

integer touch_n;

float rt;
list rts;
float mrt;//

integer i;//Хранение этой переменной, это фишка, помогающая при перезаписи не использовать поиск в массивах.

float click_time;
integer Console=0;

Check_DDOS()
{
    mrt=click_time-rt;
    if(mrt<2.0)//Если разница времени больше 2 секунд
    {
        if(touch_counter>touch_block)//Если счётчик touch_counter больше touch_block,
        {
            touch_block=touch_block+touch_counter;//порог прохождения увеличиваем на touch_counter.
            touch_counter=0;//Тогда touch_counter обнуляем, а
            if(Console)llOwnerSay("Check_DDOS: Позволяем достучаться");
            //Таким образом мы добиваемся небольшого антиДДОС-а, при котором будут игноррироваться 
        }
        else
        {
        llRegionSayTo(agent,0,"Вы нажимаете слишком часто. Ваш клик отклонён DDOS-защитой.");
        }
        touch_counter++;//Прибавляем 1 штрафное нажатие
    }
    else//Если же нажал не так часто как мы боялись,
    {
        if(touch_block>0)//и если при этом защита больше нуля,
        {
            touch_block-=(integer)mrt;//Уменьшаем защиту на количество прошедших секунд с последнего нажатия
            if(Console)llOwnerSay("Check_DDOS: Количество штрафных секунд уменьшилось на "+(string)mrt);
            if(touch_block<0)//Но если у нас получилось отрицательное значение,
            {
                touch_block=0;//Выставляем на ноль зашиту.
            }
        }
        if(Console)llOwnerSay("Check_DDOS: Законный клик прошёл успешно.");
    }
}

Save(key UUID)//Загрузка данных о пользователе в массив, если он найден, в противном случае запись новой ячейки.
{
            i=llListFindList(last_agents,[UUID]);//мы производим поиск в листе ключей переменная, являющаяся индексом найденной ячейки
            if (~i)//Это случается, если мы что то обнаружили
            {
                last_agents=llListReplaceList(last_agents, [last_agent], i, i);//Перезаписываем элемент листа ключей пользователей
                touch_counters=llListReplaceList(touch_counters, [touch_counter], i, i);//Перезаписываем элемент листа штрафных нажатий
                touch_blocks=llListReplaceList(touch_blocks,[touch_block], i, i);//Перезаписываем элемент листа блокировок
                rts=llListReplaceList(rts,[rt], i, i);//Перезаписываем элемент листа блокировок
                if(Console)llOwnerSay("Save: arrays in BOX {i="+(string)i+"}:\nlast_agents:["+(string)UUID+"]\ntouch_counters:"+(string)touch_counter+"\ntouch_blocks:"+(string)touch_block);
            }
            else//Это случается, если мы ничего не нашли
            {
                Write(UUID);
                touch_counter=0;//обнуляем попытки
                touch_block=0;//обнуляем защиту
                rt=0;//обнуляем время
            }
}

Upload(key UUID)//Загрузка из массивов данных о пользователе, если он найден.
{
   
            i=llListFindList(last_agents,[UUID]);//мы производим поиск в листе ключей переменная, являющаяся индексом найденной ячейки
            if (~i)//Это случается, если мы что то обнаружили
            {
                //last_agent=llList2Key(last_agents,i);//Возвращаем элемент листа
                touch_counter=llList2Integer(touch_counters,i);//Возвращаем элемент листа
                touch_block=llList2Integer(touch_blocks,i);//Возвращаем элемент листа
                rt=llList2Float(rts,i);//Возвращаем элемент листа
                if(Console)llOwnerSay("Upload: arrays in BOX {i="+(string)i+"}:\nlast_agents:["+(string)UUID+"]\ntouch_counters:"+(string)touch_counter+"\ntouch_blocks:"+(string)touch_block+"\nrt:"+(string)rt);
            }
            else//Это случается, если мы ничего не нашли
            {
                //last_agent=agent;//Возвращаем элемент листа
                touch_counter=0;//Возвращаем элемент листа
                touch_block=0;//Возвращаем элемент листа
                rt=0;
                Save(agent);
            }
}

Write(key UUID)
{
    if(Console)llOwnerSay("Write ++arrays:\nlast_agents:["+(string)UUID+"]\ntouch_blocks:[0]\ntouch_counters:[0]");
    last_agents=[UUID]+last_agents;//Добавляем к листу имя нажавшего. 
    touch_blocks=[0]+touch_blocks;//Добавляем к листу блокировок блокировку нажавшего...? нет. Она же равна нулю, зачем тогда.
    touch_counters=[0]+touch_blocks;//Добавляем к листу количества штрафных нажатий ячейку за значением 1.
    rts=[0]+rts;//Добавляем в память сведени о времени последнего нажатия
    
}

Delete()
{
    integer Length=llGetListLength(last_agents);//Находим длину списка.
    if(Length>32)//Если длина списков больше 32 пользователей,
    {
        Length--;//(!)Длина списка не соответствует индексу последнего пункта, она больше на 1, следовательно отнимаем единицу.
        last_agents=llDeleteSubList(last_agents, Length, Length);//Удаляем данные о последнем агенте,
        touch_blocks=llDeleteSubList(touch_blocks, Length, Length);//Удаляем данные о мощности блокировки последнего агента,
        touch_counters=llDeleteSubList(touch_counters, Length, Length);//Удаляем данные о штрафных нажатиях последнего агента.
        rts=llDeleteSubList(rts, Length, Length);//Удаляем данные о времени нажатия последнего агента.
    }
}

default
{
    state_entry(){if(Console)llOwnerSay("=============START===========");}
    touch_start(integer TN_UUID)
    {
        touch_n++;//Увеличиваем значение глобального счётчика на 1,
        agent=llDetectedKey(0);//Определяем новую переменную "агент", и 
        click_time=llGetTime();
        
        if(agent==last_agent)//Если ключи двух пользователей равны, сделовательно: предыдущий пользователь это текущий пользователь,
        {
            Check_DDOS();//Переходим к отождествлению есть ли DDOS.
        }

        else if (agent!=last_agent)//Если нажал не тот же пользователь что и до этого
        {

        if(last_agent)
        Save(last_agent);
        
        Upload(agent);
        
        Check_DDOS();
        
        Delete();
        
        }
        last_agent=agent;
        if(Console)llOwnerSay("TN_UUID:"+(string)TN_UUID+" / touch_n="+(string)touch_n+" Попытки touch_counter="+(string)touch_counter+" Защита touch_block="+(string)touch_block+" / Защита временем RT="+(string)rt+" Время t:"+(string)llGetTime()+" Разница: "+(string)(llGetTime()-rt)+" Лист: "+llList2CSV(last_agents));
        rt=llGetTime();
    }
    touch_end(integer TN_UUID)
    {
        if((llGetTime()-click_time)>10.0)//Если разница во времени между началом нажатия и концом больше 10 секунд,
        {
            if(Console){llOwnerSay("Доступ к консоли разработчика отключен.");Console=0;}
            else {llOwnerSay("Получен доступ к консоли разработчика.");Console=1;}
        }
    }
}
