unless Rails.env.production?
  # Create Questions for the Web 3.0 course
  u_learn_logo_url = "https://play-lh.googleusercontent.com/rNgpb_TlfsoaKOqFwf8CFDpVjWymv8Zdh8a3EEz8UjEEhND-oWWpIxbeQSoN7akz-nE"
  web3_course = Course.find_by(title: "Web 3.0")

  if Question.count == 0
    Question.create(
      [
        {
          course: web3_course,
          question_number: 1,
          question: "What is Web 3.0?",
          question_image_url: u_learn_logo_url,
          options: [
            {
              id: 1,
              text: "A game"
            },
            {
              id: 2,
              text: "Life"
            },
            {
              id: 3,
              text: "New Decentralized technology"
            },
            {
              id: 4,
              text: "Another game"
            }
          ],
          answer: "3",
          answer_image_url: u_learn_logo_url,
          explanation: "Who really knows?",
          explanation_image_url: u_learn_logo_url,
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 2,
          question: "What is the Blockchain",
          options: [
            {
              id: 1,
              text: "New tech meant to enhance data movement"
            },
            {
              id: 2,
              text: "Bitcoin"
            },
            {
              id: 3,
              text: "Crypto"
            },
            {
              id: 4,
              text: "Another crypto"
            }
          ],
          answer: "1",
          explanation: "Who really knows?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 3,
          question: "What decade did Web 2.0 start getting popular?",
          options: [
            {
              id: 1,
              text: "2000's",
            },
            {
              id: 2,
              text: "1990's"
            },
            {
              id: 3,
              text: "2010's"
            },
            {
              id: 4,
              text: "1980's"
            }
          ],
          answer: "1",
          explanation: "Who really knows?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 4,
          question: "What is the most popular Crypto Currency",
          options: [
            {
              id: 1,
              text: "Ether"
            },
            {
              id: 2,
              text: "DOGE"
            },
            {
              id: 3,
              text: "Solana"
            },
            {
              id: 4,
              text: "Bitcoin"
            }
          ],
          answer: "4",
          explanation: "Who really knows?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 5,
          question: "What is Bitcoins acronym?",
          options: [
            {
              id: 1,
              text: "ETH",
              image_url: u_learn_logo_url
            },
            {
              id: 2,
              text: "BTC",
              image_url: u_learn_logo_url
            },
            {
              id: 3,
              text: "BITC",
              image_url: u_learn_logo_url
            },
            {
              id: 4,
              text: "BTN",
              image_url: u_learn_logo_url
            }
          ],
          answer: "2",
          multiplier: 2,
          explanation: "Who really knows?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 6,
          question: "Which popular meme crypto did Elon Musk promote?",
          options: [
            {
              id: 1,
              text: "SHIB"
            },
            {
              id: 2,
              text: "DOGE"
            },
            {
              id: 3,
              text: "Solana"
            },
            {
              id: 4,
              text: "DOT"
            }
          ],
          answer: "2",
          explanation: "Who really knows?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 7,
          question: "Who founded Ether and PolkaDOT?",
          options: [
            {
              id: 1,
              text: "Jonny Bitcoin"
            },
            {
              id: 2,
              text: "Gavin James Wood"
            },
            {
              id: 3,
              text: "Vitarik Buterin"
            },
            {
              id: 4,
              text: "Zug Polka"
            }
          ],
          answer: "2",
          multiplier: 3,
          explanation: "Who really knows?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 8,
          question: "Who founded Bitcoin?",
          options: [
            {
              id: 1,
              text: "CZ Binance"
            },
            {
              id: 2,
              text: "Vitalik Buterin"
            },
            {
              id: 3,
              text: "Satoshi Nakamoto"
            },
            {
              id: 4,
              text: "Nick Szabo"
            }
          ],
          answer: "3",
          explanation: "Who really knows?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 9,
          question: "What's the relationship between Web 3.0 and Crypto?",
          options: [
            {
              id: 1,
              text: "Both bring blood money"
            },
            {
              id: 2,
              text: "Both use Blockchain"
            },
            {
              id: 3,
              text: "Both are fancy"
            },
            {
              id: 4,
              text: "Both operate through decentralized protocols"
            }
          ],
          answer: "4",
          explanation: "Who really knows?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 10,
          question: "Which is not a key feature of Web 3.0?",
          options: [
            {
              id: 1,
              text: "Ubiquity"
            },
            {
              id: 2,
              text: "Financial Centralization"
            },
            {
              id: 3,
              text: "Semantic Web"
            },
            {
              id: 4,
              text: "Artificial Intelligence"
            }
          ],
          answer: "2",
          multiplier: 4,
          explanation: "You really fell for that?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 11,
          question: "Why is Web 3.0 still limited?",
          options: [
            {
              id: 1,
              text: "Multiple Languages"
            },
            {
              id: 2,
              text: "Accessibility and Cost"
            },
            {
              id: 3,
              text: "User Experience"
            },
            {
              id: 4,
              text: "Centralized Infrastructure"
            }
          ],
          answer: "1",
          multiplier: 3,
          explanation: "You really fell for that?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 12,
          question: "Which of these don't highlight the importance of Web 3.0?",
          options: [
            {
              id: 1,
              text: "Ownership"
            },
            {
              id: 2,
              text: "Censorship resistance"
            },
            {
              id: 3,
              text: "Identity"
            },
            {
              id: 4,
              text: "User likeability"
            }
          ],
          answer: "4",
          multiplier: 2,
          explanation: "You really fell for that?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 13,
          question: "What does NFT stand for?",
          options: [
            {
              id: 1,
              text: "New Future Technology"
            },
            {
              id: 2,
              text: "New Fungible Token"
            },
            {
              id: 3,
              text: "Non-Fungible Token"
            },
            {
              id: 4,
              text: "Neo-Fungible Token"
            }
          ],
          answer: "3",
          explanation: "You really fell for that?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 14,
          question: "What makes an NFT valuable?",
          options: [
            {
              id: 1,
              text: "It's fancy name"
            },
            {
              id: 2,
              text: "Its one-of-a-kind characteristic "
            },
            {
              id: 3,
              text: "It's not really valuable"
            },
            {
              id: 4,
              text: "None of the above"
            }
          ],
          answer: "2",
          explanation: "Who knows?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 15,
          question: "Which of these is not a popular NFT platform?",
          options: [
            {
              id: 1,
              text: "Opensea"
            },
            {
              id: 2,
              text: "Binance"
            },
            {
              id: 3,
              text: "Mintable"
            },
            {
              id: 4,
              text: "Coinbase"
            }
          ],
          answer: "4",
          multiplier: 3,
          explanation: "As of 2022 April, Coinbase is not yet one",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 16,
          question: "Are NFTs the future of art and collectibles?",
          options: [
            {
              id: 1,
              text: "Yes"
            },
            {
              id: 2,
              text: "No"
            },
            {
              id: 3,
              text: "Depends on who you ask"
            }
          ],
          answer: "3",
          multiplier: 2,
          explanation: "Who really knows?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 17,
          question: "Web 2.0 will be phased out by 2022 end",
          options: [
            {
              id: 1,
              text: "True"
            },
            {
              id: 2,
              text: "False"
            }
          ],
          answer: "3",
          multiplier: 2,
          explanation: "Who really knows?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 18,
          question: "Will Web 3.0 ever be the new standard",
          options: [
            {
              id: 1,
              text: "It could potentially happen"
            },
            {
              id: 2,
              text: "Yes"
            },
            {
              id: 3,
              text: "No"
            },
            {
              id: 4,
              text: "None of the above"
            },
            {
              id: 5,
              text: "All of the above"
            }
          ],
          answer: "5",
          multiplier: 2,
          explanation: "Who really knows?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 19,
          question: "The current Web standard right now is __________",
          answer: "Web 2.0|Web2|2.0|2",
          multiplier: 3,
          explanation: "Who really knows?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 20,
          question: "Terra Nullius, the first NFT on the Ethereum blockchain was minted in what year?",
          answer: "2015|August 2015|August 7, 2015",
          multiplier: 4,
          explanation: "Who really knows?",
          publish_status: :publish_status_published
        }
      ]
    )
  end
end
