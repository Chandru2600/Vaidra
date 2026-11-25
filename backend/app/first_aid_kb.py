"""
Vaidra first-aid knowledge base.

General first-aid information only — NOT medical advice, NOT a diagnosis,
and NEVER a prescription. In an emergency call 112.

Rules enforced in this file:
- No medication names, no dosages, no prescription advice anywhere.
- Every guide carries the same disclaimer.
- Content follows standard first-aid guidance (Red Cross / WHO style):
  what to do, what NOT to do, and when to call 112.

NOTE: the brief listed 12 guides but named 13 — all 13 named guides are
included here.
"""

DISCLAIMER = "General information only, not medical advice. In an emergency call 112."

GUIDES = [
    {
        "id": "severe-bleeding",
        "title": "Severe Bleeding",
        "danger_signs": [
            "Bleeding that does not stop after 10 minutes of firm pressure",
            "Blood spurting or pooling rapidly",
            "Person becomes pale, cold, sweaty or confused",
            "Bleeding from the head, neck or torso",
        ],
        "steps": [
            "Call 112 immediately for severe bleeding.",
            "Put on gloves if available and press firmly on the wound with a clean cloth or bandage.",
            "Keep pressing without lifting the cloth to check — add more layers on top if blood soaks through.",
            "If possible, raise the injured limb above heart level while pressing.",
            "Keep the person still, warm and lying down; talk calmly to them.",
            "Do not give food or drink.",
            "Stay with them until emergency help arrives.",
        ],
        "what_not_to_do": [
            "Do not remove an object stuck in the wound — press around it instead.",
            "Do not use a tourniquet unless you are trained to do so.",
            "Do not remove a soaked bandage — add another on top.",
        ],
        "call_112_when": [
            "Bleeding does not stop after 10 minutes of pressure",
            "Blood is spurting or pooling fast",
            "The person shows signs of shock (pale, cold, confused)",
            "The wound is deep, large, or on the head, neck or torso",
        ],
    },
    {
        "id": "burns",
        "title": "Burns",
        "danger_signs": [
            "Burn larger than the person's palm",
            "Burn on the face, hands, feet, genitals or over a joint",
            "Skin looks white, charred or numb",
            "Burn caused by chemicals or electricity",
        ],
        "steps": [
            "Move the person away from the heat source.",
            "Cool the burn with clean running water for at least 10 minutes.",
            "Remove rings, watches and loose clothing near the burn — do not peel off clothing stuck to the skin.",
            "Cover the burn loosely with a clean, non-stick dressing or cling film.",
            "Keep the person warm and comfortable.",
            "Seek medical care for anything larger than a small burn.",
        ],
        "what_not_to_do": [
            "Do not apply ice, butter, toothpaste or creams.",
            "Do not pop blisters.",
            "Do not peel off clothing stuck to the burn.",
        ],
        "call_112_when": [
            "Burn is large, deep, or on the face, hands, feet or genitals",
            "Skin is white or charred",
            "Burn was caused by chemicals, electricity or an explosion",
            "The person is a young child or has difficulty breathing",
        ],
    },
    {
        "id": "choking-adult",
        "title": "Choking (Adult)",
        "danger_signs": [
            "Person cannot speak, cough or breathe",
            "Face turning blue",
            "Person clutching their throat",
        ],
        "steps": [
            "Ask: 'Are you choking?' If they can cough or speak, encourage them to keep coughing.",
            "If they cannot breathe or speak, stand behind them and give 5 sharp back blows between the shoulder blades with the heel of your hand.",
            "If still blocked, give 5 abdominal thrusts: fist just above the navel, pull sharply in and up.",
            "Alternate 5 back blows and 5 abdominal thrusts until the object clears.",
            "Call 112 if the blockage does not clear quickly.",
            "If the person becomes unconscious, call 112 and start CPR.",
        ],
        "what_not_to_do": [
            "Do not hit the back of someone who is coughing effectively.",
            "Do not do blind finger sweeps inside the mouth.",
            "Do not give them water to drink.",
        ],
        "call_112_when": [
            "The blockage does not clear after back blows and thrusts",
            "The person becomes unconscious",
            "Breathing remains difficult after the object clears",
        ],
    },
    {
        "id": "choking-child-infant",
        "title": "Choking (Child / Infant)",
        "danger_signs": [
            "Baby or child cannot cry, cough or breathe",
            "Lips or face turning blue",
            "Weak or silent cough",
        ],
        "steps": [
            "For a baby under 1 year: hold them face down along your forearm, head lower than the chest. Give 5 back blows between the shoulder blades.",
            "Turn the baby face up and give 5 chest thrusts with two fingers on the centre of the chest.",
            "Repeat 5 back blows and 5 chest thrusts until the object clears or help arrives.",
            "For a child over 1 year: use 5 back blows and 5 abdominal thrusts, as for an adult but with less force.",
            "Call 112 if the blockage does not clear quickly.",
        ],
        "what_not_to_do": [
            "Do not do blind finger sweeps.",
            "Do not hold a baby upside down by the legs.",
            "Do not give abdominal thrusts to a baby under 1 year.",
        ],
        "call_112_when": [
            "The blockage does not clear",
            "The baby or child becomes unconscious or limp",
            "Breathing stays difficult after the object clears",
        ],
    },
    {
        "id": "cpr-basics",
        "title": "CPR Basics",
        "danger_signs": [
            "Person is unresponsive and not breathing normally",
            "Gasping or agonal breathing only",
            "No pulse (if you are trained to check)",
        ],
        "steps": [
            "Check responsiveness — tap the shoulders and shout. If there is no response, call 112 immediately (or ask someone to).",
            "Lay the person on their back on a firm surface.",
            "Place the heel of one hand on the centre of the chest, the other hand on top, and push hard and fast — about 5-6 cm deep, 100-120 times per minute.",
            "If trained, give 30 compressions then 2 rescue breaths, and repeat.",
            "If not trained, keep doing hands-only compressions without stopping.",
            "Continue until help arrives or the person starts breathing normally.",
        ],
        "what_not_to_do": [
            "Do not stop compressions to check repeatedly.",
            "Do not give rescue breaths if you are not trained — hands-only CPR is better than nothing.",
            "Do not move the person unless they are in danger.",
        ],
        "call_112_when": [
            "Always — call 112 immediately for anyone unresponsive and not breathing normally",
        ],
    },
    {
        "id": "fracture",
        "title": "Fracture (Suspected Broken Bone)",
        "danger_signs": [
            "Bone visibly out of place or poking through skin",
            "Severe pain, swelling or deformity",
            "Numbness or loss of feeling below the injury",
            "Injury to the head, neck or back",
        ],
        "steps": [
            "Keep the person still — do not move the injured limb.",
            "Support the limb in the position you found it, using rolled cloth or a splint if available.",
            "Apply a cold pack wrapped in cloth to reduce swelling.",
            "If there is bleeding from an open fracture, press gently around the wound with a clean cloth.",
            "Call 112 or take them to a hospital. Do not let them eat or drink in case surgery is needed.",
        ],
        "what_not_to_do": [
            "Do not try to straighten or push a bone back into place.",
            "Do not move a person with a suspected spine, neck or head injury.",
            "Do not apply a tight bandage that cuts off circulation.",
        ],
        "call_112_when": [
            "Bone is visible or the limb is badly deformed",
            "The person cannot move the limb or has lost feeling",
            "The injury involves the head, neck or back",
            "There is heavy bleeding from the wound",
        ],
    },
    {
        "id": "sprain",
        "title": "Sprain",
        "danger_signs": [
            "Cannot bear weight or move the joint at all",
            "Joint looks deformed",
            "Numbness or coldness below the injury",
            "Severe swelling within minutes",
        ],
        "steps": [
            "Rest the injured joint — stop using it.",
            "Apply a cold pack wrapped in cloth for 15-20 minutes, several times a day.",
            "Compress gently with a bandage — snug, not tight.",
            "Elevate the joint above heart level to reduce swelling.",
            "Avoid heat and massage for the first 48 hours.",
        ],
        "what_not_to_do": [
            "Do not apply heat in the first 48 hours.",
            "Do not wrap the bandage so tightly that toes or fingers go numb or blue.",
            "Do not 'walk it off' if you cannot bear weight.",
        ],
        "call_112_when": [
            "You cannot move the joint or bear weight on it",
            "The joint looks deformed or numb",
            "Swelling is severe or pain keeps worsening after a day",
        ],
    },
    {
        "id": "snake-bite",
        "title": "Snake Bite",
        "danger_signs": [
            "Two puncture marks with rapid swelling",
            "Severe pain, nausea, blurred vision or difficulty breathing",
            "Bite on the face, neck or torso",
            "The person becomes drowsy or collapses",
        ],
        "steps": [
            "Keep the person calm and still — movement spreads venom faster.",
            "Call 112 or get to a hospital as fast as possible.",
            "Keep the bitten limb still and below heart level.",
            "Remove rings, watches and tight clothing near the bite before swelling starts.",
            "Note the time of the bite and, only if safe, the snake's appearance.",
            "Keep the person lying down and monitor breathing.",
        ],
        "what_not_to_do": [
            "Do not suck the venom out or cut the wound.",
            "Do not apply a tourniquet.",
            "Do not apply ice or ointments.",
            "Do not try to catch or kill the snake.",
        ],
        "call_112_when": [
            "Always — every snake bite needs hospital assessment urgently",
            "Immediately if there is swelling, severe pain, breathing difficulty or drowsiness",
        ],
    },
    {
        "id": "fainting",
        "title": "Fainting",
        "danger_signs": [
            "Does not wake up within a minute",
            "Fainted during exercise or while lying down",
            "Chest pain, breathlessness or irregular heartbeat",
            "Injury from the fall",
            "Faints repeatedly",
        ],
        "steps": [
            "Lay the person flat on their back and raise their legs about 30 cm.",
            "Loosen tight clothing around the neck and waist.",
            "Make sure they have fresh air.",
            "When they wake, keep them lying down for a few minutes, then sit up slowly.",
            "Give small sips of water once fully awake.",
            "If they do not wake within a minute, call 112 and check breathing.",
        ],
        "what_not_to_do": [
            "Do not slap, shake or pour water on them.",
            "Do not stand them up quickly.",
            "Do not give food or drink while they are unconscious.",
        ],
        "call_112_when": [
            "They do not wake within a minute",
            "They fainted during exercise, while lying down, or for no clear reason",
            "There is chest pain, breathlessness, or an injury from the fall",
        ],
    },
    {
        "id": "heatstroke",
        "title": "Heatstroke",
        "danger_signs": [
            "Body temperature very high, skin hot and dry or sweaty",
            "Confusion, slurred speech or loss of consciousness",
            "Rapid heartbeat or breathing",
            "Vomiting, severe headache or muscle cramps",
        ],
        "steps": [
            "Call 112 — heatstroke is a medical emergency.",
            "Move the person to a cool, shaded place immediately.",
            "Remove excess clothing and cool them with water, wet cloths or a fan.",
            "Place cold packs on the neck, armpits and groin if available.",
            "If they are conscious and alert, give small sips of cool water.",
            "Keep cooling until help arrives.",
        ],
        "what_not_to_do": [
            "Do not give alcohol or caffeinated drinks.",
            "Do not give water if the person is confused or unconscious.",
            "Do not delay cooling while waiting for help.",
        ],
        "call_112_when": [
            "Always — heatstroke can be fatal without emergency treatment",
            "Immediately if the person is confused, unconscious or vomiting",
        ],
    },
    {
        "id": "allergic-reaction",
        "title": "Allergic Reaction (Anaphylaxis)",
        "danger_signs": [
            "Swelling of lips, tongue or face",
            "Throat tightness or difficulty breathing or swallowing",
            "Widespread rash with dizziness or collapse",
            "Known severe allergy and exposure to the trigger",
        ],
        "steps": [
            "Call 112 immediately if there is any breathing difficulty or swelling — do not wait to see if it gets worse.",
            "Help the person use their own prescribed allergy injector if they carry one.",
            "Lay the person flat; if they are vomiting or struggling to breathe, lay them on their side.",
            "Do not let them stand or walk — this can make a severe reaction worse.",
            "Remove the trigger if it is still present (for example a sting) without putting yourself at risk.",
            "Stay with them and monitor breathing until help arrives.",
        ],
        "what_not_to_do": [
            "Do not wait to see if symptoms pass.",
            "Do not give food or drink.",
            "Do not put them in a cold bath or shower.",
        ],
        "call_112_when": [
            "Any swelling of the face, lips or tongue",
            "Any difficulty breathing or swallowing",
            "Dizziness, collapse, or a known severe allergy with exposure",
        ],
    },
    {
        "id": "nosebleed",
        "title": "Nosebleed",
        "danger_signs": [
            "Bleeding lasts more than 20-30 minutes",
            "Heavy bleeding or blood running down the throat",
            "Bleeding after a head injury",
            "Person has a known bleeding disorder",
        ],
        "steps": [
            "Sit upright and lean slightly forward.",
            "Pinch the soft part of the nose firmly and hold for 10-15 minutes without checking.",
            "Breathe through the mouth.",
            "Apply a cold cloth on the bridge of the nose.",
            "Once bleeding stops, avoid blowing the nose or bending over for a few hours.",
        ],
        "what_not_to_do": [
            "Do not tilt the head back — blood will run down the throat.",
            "Do not stuff cotton or tissue deep into the nose.",
            "Do not pick or blow the nose afterwards.",
        ],
        "call_112_when": [
            "Bleeding continues for more than 20-30 minutes",
            "Bleeding is heavy or follows a head injury",
            "The person feels faint or has a known bleeding disorder",
        ],
    },
    {
        "id": "seizure",
        "title": "Seizure",
        "danger_signs": [
            "Seizure lasts longer than 5 minutes",
            "Repeated seizures without recovery in between",
            "Breathing difficulty or lips turning blue",
            "Seizure in water, or a serious injury during the seizure",
            "First-ever seizure",
        ],
        "steps": [
            "Stay calm and time the seizure.",
            "Move hard or sharp objects away; cushion the head with something soft.",
            "Do not restrain the person — let the movements happen.",
            "Once the shaking stops, roll them onto their side (recovery position) and check breathing.",
            "Stay with them until they are fully awake and aware.",
            "Note how long the seizure lasted to tell medical staff.",
        ],
        "what_not_to_do": [
            "Do not put anything in the person's mouth.",
            "Do not hold them down.",
            "Do not give food, drink or medicine during the seizure.",
        ],
        "call_112_when": [
            "Seizure lasts longer than 5 minutes",
            "Another seizure starts before they recover",
            "They have trouble breathing, are injured, or it is their first seizure",
        ],
    },
]


def _with_disclaimer(guide: dict) -> dict:
    return {**guide, "disclaimer": DISCLAIMER}


def list_guides() -> list:
    """All guides, each carrying the disclaimer."""
    return [_with_disclaimer(g) for g in GUIDES]


def get_guide(guide_id: str) -> dict | None:
    """One guide by id, or None if unknown."""
    for guide in GUIDES:
        if guide["id"] == guide_id:
            return _with_disclaimer(guide)
    return None
