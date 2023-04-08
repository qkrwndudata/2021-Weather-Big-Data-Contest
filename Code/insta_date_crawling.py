## 인스타그램에 해시태그를 입력해 나오는 게시글을 크롤링하는 코드입니다.

# 라이브러리 호출
import time
import os
from selenium import webdriver
from selenium.webdriver.common.action_chains import ActionChains
import pandas as pd
from selenium.webdriver.common.keys import Keys

path = 'C:/Users/Park JuYoung/Desktop/chromedriver.exe'

search_word = input('검색할 단어를 입력하세요: ')
tag_n = input('가져올 태그의 숫자를 입력하세요: ')

driver = webdriver.Chrome(path)
action = ActionChains(driver)

url = 'https://www.instagram.com/explore/tags/'+search_word+'/'

driver.get(url)
driver.maximize_window()


########### 인스타그램 오픈준비 완료 ############

time.sleep(10)
driver.find_element_by_css_selector('.sqdOP.yWX7d.y3zKF').click()

time.sleep(5)
driver.find_element_by_css_selector('.sqdOP.L3NKy.y3zKF').click()

time.sleep(5)
driver.find_element_by_id("email").send_keys('01050275624')
driver.find_element_by_id("pass").send_keys('jyp624317@')

time.sleep(5)
driver.find_element_by_id("loginbutton").click()

time.sleep(10)
driver.get(url)
time.sleep(10)

insta_dict = {'date': [],
              'text': [],
              'hashtag': []}

first_post = driver.find_element_by_class_name('eLAPa')
first_post.click()

seq = 0
start = time.time()

while True:
    try:
        if driver.find_element_by_css_selector('a._65Bje.coreSpriteRightPaginationArrow'):
            if seq % 20 == 0:
                print('{}번째 수집 중'.format(seq), time.time() - start, sep='\t')



            ## 시간정보 수집
            time.sleep(2)
            time_raw = driver.find_element_by_css_selector('time.FH9sR.Nzb55')
            time_info = pd.to_datetime(time_raw.get_attribute('datetime')).normalize()
            insta_dict['date'].append(time_info)



            ##text 정보수집
            raw_info = driver.find_element_by_css_selector('div.C4VMK').text.split()
            text = []
            for i in range(len(raw_info)):
                ## 첫번째 text는 아이디니까 제외
                if i == 0:
                    pass
                ## 두번째부터 시작
                else:
                    if '#' in raw_info[i]:
                        pass
                    else:
                        text.append(raw_info[i])
            clean_text = ' '.join(text)
            insta_dict['text'].append(clean_text)

            ##hashtag 수집
            raw_tags = driver.find_elements_by_css_selector('a.xil3i')
            hash_tag = []
            for i in range(len(raw_tags)):
                if raw_tags[i].text == '':
                    pass
                else:
                    hash_tag.append(raw_tags[i].text)

            insta_dict['hashtag'].append(hash_tag)

            seq += 1

            if seq == 1000:
                break

            driver.find_element_by_css_selector('a._65Bje.coreSpriteRightPaginationArrow').click()
            time.sleep(1.5)


        else:
            break

    except:
        driver.find_element_by_css_selector('a._65Bje.coreSpriteRightPaginationArrow').click()
        time.sleep(2)

test = pd.DataFrame.from_dict(insta_dict)
