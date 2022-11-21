package hyphin.service;

import hyphin.dto.CcyPairDto;
import hyphin.dto.EcStaticDataDailyDto;
import hyphin.dto.mappers.CcyPairMapper;
import hyphin.dto.mappers.EcStaticDataDailyMapper;
import hyphin.enums.Sentiment;
import hyphin.model.CcyPair;
import hyphin.model.User;
import hyphin.model.currency.CurrencyRatesBlend;
import hyphin.model.endchallenge.EndChallengeSession;
import hyphin.repository.CcyPairRepository;
import hyphin.repository.EcStaticDataDailyRepository;
import hyphin.repository.UserAuditRepository;
import hyphin.repository.currency.CurrencyRatesBlendRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import javax.servlet.http.HttpSession;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class EndChallengeService {

    private final CurrencyRatesBlendRepository currencyRatesBlendRepository;

    public List<CurrencyRatesBlend> getChartData(String pair) {
        return currencyRatesBlendRepository.findAll().stream()
                .filter(currencyRatesBlend -> currencyRatesBlend.getCcyPair().equals(pair))
                .map(blend -> {
                    blend.setBlendOpen(trimDigits(blend.getBlendOpen()));
                    blend.setBlendHigh(trimDigits(blend.getBlendHigh()));
                    blend.setBlendLow(trimDigits(blend.getBlendLow()));
                    blend.setBlendClose(trimDigits(blend.getBlendClose()));

                    return blend;
                }).collect(Collectors.toList());
    }

    private Double trimDigits(Double arg) {
        if (Objects.nonNull(arg)) {
            return Math.floor(arg * 10000) / 10000;
        }

        return arg;
    }

    private final UserAuditRepository userAuditRepository;
    private final CcyPairRepository ccyPairRepository;
    private final EcStaticDataDailyRepository ecStaticDataDailyRepository;


    private final CcyPairMapper ccyPairMapper;
    private final EcStaticDataDailyMapper ecStaticDataDailyMapper;

    private static final SimpleDateFormat jdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS");
    private static final String END_CHALLENGE_ELEMENT_ID = "?";
    private static final long SESSION_LIVE_TIME = 1000 * 60 * 60;
    private static final long GAME_TIMEOUT_MILLIS = 1000 * 45;
    private ConcurrentHashMap<String, EndChallengeSession> sessions = new ConcurrentHashMap<>();
    List<CcyPairDto> allPairs = new ArrayList<>();

//    @PostConstruct
//    private void init(){
//        System.out.println("initPairs.....");
//        allPairs = StreamSupport.stream(ccyPairRepository.findAll().spliterator(), false)
//                .map(ccyPairMapper::mapToDto).collect(Collectors.toList());
//        System.out.println("initPairs..... finished");
//    }

    public void start(HttpSession session) {
        User user = (User) session.getAttribute("User-entity");
        List<CcyPair> ccyPairs = ccyPairRepository.getCcyPairsByUserParams(user.getRegion(), user.getPreferenceType(), user.getDisplayPriority());

        List<CcyPairDto> collect = ccyPairs
                .stream()
                .map(ccyPairMapper::mapToDto)
                .collect(Collectors.toList());

        String endChallengeSessionId = session.getId() + System.currentTimeMillis();

        session.setAttribute("end-challenge-session-id", endChallengeSessionId);
        EndChallengeSession endChallengeSession = new EndChallengeSession(endChallengeSessionId, user);
        endChallengeSession.setPairs(collect);
        sessions.put(endChallengeSession.getEndChallengeSessionId(), endChallengeSession);
    }

    public void chosePair(HttpSession session, String pair) {
        EndChallengeSession endChallengeSession = sessions.get(getEndChallengeSessionId(session));
        endChallengeSession.setChosenPair(endChallengeSession.getPairs().stream().filter(ccyPairDto -> ccyPairDto.getCurrencyPairFormatted().equals(pair)).findAny().orElseThrow(RuntimeException::new));
    }

    public void choseSentiment(HttpSession session, Sentiment sentiment) {
        EndChallengeSession endChallengeSession = sessions.get(getEndChallengeSessionId(session));
        endChallengeSession.setSentiment(sentiment);
    }

    public CcyPairDto getChosenPair(HttpSession session) {
        EndChallengeSession endChallengeSession = sessions.get(getEndChallengeSessionId(session));
        return endChallengeSession.getChosenPair();
    }
    public EcStaticDataDailyDto getEcStaticDataDaily(HttpSession session) {
        EndChallengeSession endChallengeSession = sessions.get(getEndChallengeSessionId(session));
        return ecStaticDataDailyMapper.mapToDto(ecStaticDataDailyRepository.getByCcyPair(endChallengeSession.getChosenPair().getCurrencyPair()));
    }


    public List<CcyPairDto> getAllPairs(HttpSession session) {
        return sessions.get(getEndChallengeSessionId(session)).getPairs();
    }

    private String getEndChallengeSessionId(HttpSession session) {
        if (Objects.isNull(session.getAttribute("end-challenge-session-id"))) {
            return "none";
        }

        return (String) session.getAttribute("end-challenge-session-id");
    }
}
