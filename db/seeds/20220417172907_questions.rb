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
              order: 1,
              text: "A game"
            },
            {
              order: 2,
              text: "Life"
            },
            {
              order: 3,
              text: "New Decentralized technology"
            },
            {
              order: 4,
              text: "Another game"
            }
          ],
          answer: [3],
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
              order: 1,
              text: "New tech meant to enhance data movement"
            },
            {
              order: 2,
              text: "Bitcoin"
            },
            {
              order: 3,
              text: "Crypto"
            },
            {
              order: 4,
              text: "Another crypto"
            }
          ],
          answer: [1],
          explanation: "Who really knows?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 3,
          question: "What decade did Web 2.0 start getting popular?",
          options: [
            {
              order: 1,
              text: "2000's",
            },
            {
              order: 2,
              text: "1990's"
            },
            {
              order: 3,
              text: "2010's"
            },
            {
              order: 4,
              text: "1980's"
            }
          ],
          answer: [1],
          explanation: "Who really knows?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 4,
          question: "What is the most popular Crypto Currency",
          options: [
            {
              order: 1,
              text: "Ether"
            },
            {
              order: 2,
              text: "DOGE"
            },
            {
              order: 3,
              text: "Solana"
            },
            {
              order: 4,
              text: "Bitcoin"
            }
          ],
          answer: [4],
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
          answer: [2],
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
              order: 1,
              text: "SHIB"
            },
            {
              order: 2,
              text: "DOGE"
            },
            {
              order: 3,
              text: "Solana"
            },
            {
              order: 4,
              text: "DOT"
            }
          ],
          answer: [2],
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 7,
          question: "Who founded Ether and PolkaDOT?",
          options: [
            {
              order: 1,
              text: "Jonny Bitcoin"
            },
            {
              order: 2,
              text: "Gavin James Wood"
            },
            {
              order: 3,
              text: "Vitarik Buterin"
            },
            {
              order: 4,
              text: "Zug Polka"
            }
          ],
          answer: [2],
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
              order: 1,
              text: "CZ Binance"
            },
            {
              order: 2,
              text: "Vitalik Buterin"
            },
            {
              order: 3,
              text: "Satoshi Nakamoto"
            },
            {
              order: 4,
              text: "Nick Szabo"
            }
          ],
          answer: [3],
          explanation: "Who really knows?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 9,
          question: "What's the relationship between Web 3.0 and Crypto?",
          options: [
            {
              order: 1,
              text: "Both bring blood money"
            },
            {
              order: 2,
              text: "Both use Blockchain"
            },
            {
              order: 3,
              text: "Both are fancy"
            },
            {
              order: 4,
              text: "Both operate through decentralized protocols"
            }
          ],
          answer: [4],
          explanation: "Who really knows?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 10,
          question: "Which is not a key feature of Web 3.0?",
          options: [
            {
              order: 1,
              text: "Ubiquity"
            },
            {
              order: 2,
              text: "Financial Centralization"
            },
            {
              order: 3,
              text: "Semantic Web"
            },
            {
              order: 4,
              text: "Artificial Intelligence"
            }
          ],
          answer: [2],
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
              order: 1,
              text: "Multiple Languages"
            },
            {
              order: 2,
              text: "Accessibility and Cost"
            },
            {
              order: 3,
              text: "User Experience"
            },
            {
              order: 4,
              text: "Centralized Infrastructure"
            }
          ],
          answer: [1],
          multiplier: 3,
          explanation: "You really fell for that?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 12,
          question: "Which of these highlight the importance of Web 3.0?",
          options: [
            {
              order: 1,
              text: "Apes"
            },
            {
              order: 2,
              text: "Censorship resistance"
            },
            {
              order: 3,
              text: "Identity"
            },
            {
              order: 4,
              text: "User likeability"
            }
          ],
          multi_answer: true,
          answer: [2, 3],
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
              order: 1,
              text: "New Future Technology"
            },
            {
              order: 2,
              text: "New Fungible Token"
            },
            {
              order: 3,
              text: "Non-Fungible Token"
            },
            {
              order: 4,
              text: "Neo-Fungible Token"
            }
          ],
          answer: [3],
          explanation: "You really fell for that?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 14,
          question: "What makes an NFT valuable?",
          options: [
            {
              order: 1,
              text: "It's fancy name"
            },
            {
              order: 2,
              text: "Its one-of-a-kind characteristic "
            },
            {
              order: 3,
              text: "It's not really valuable"
            },
            {
              order: 4,
              text: "None of the above"
            }
          ],
          answer: [2],
          explanation: "Who knows?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 15,
          question: "Which of these is not a popular NFT platform?",
          options: [
            {
              order: 1,
              text: "Opensea"
            },
            {
              order: 2,
              text: "Binance"
            },
            {
              order: 3,
              text: "Mintable"
            },
            {
              order: 4,
              text: "Coinbase"
            }
          ],
          answer: [4],
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
              order: 1,
              text: "Yes"
            },
            {
              order: 2,
              text: "No"
            },
            {
              order: 3,
              text: "Depends on who you ask"
            }
          ],
          answer: [3],
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
              order: 1,
              text: "True"
            },
            {
              order: 2,
              text: "False"
            }
          ],
          answer: [3],
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
              order: 1,
              text: "It could potentially happen"
            },
            {
              order: 2,
              text: "Yes"
            },
            {
              order: 3,
              text: "No"
            },
            {
              order: 4,
              text: "None of the above"
            },
            {
              order: 5,
              text: "All of the above"
            }
          ],
          answer: [5],
          multiplier: 2,
          explanation: "Who really knows?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 19,
          question: "The current Web standard right now is __________",
          answer: ["Web 2.0", "Web 2", "2.0", "2"],
          multiplier: 3,
          explanation: "Who really knows?",
          publish_status: :publish_status_published
        },
        {
          course: web3_course,
          question_number: 20,
          question: "Terra Nullius, the first NFT on the Ethereum blockchain was minted in what year?",
          answer: ["2015", "August 2015", "August 7, 2015"],
          multiplier: 4,
          explanation: "Who really knows?",
          publish_status: :publish_status_published
        }
      ]
    )
  end
end
